# distutils: language = c++
# cython: language_level=3

from cpython cimport bool

from collections import defaultdict
from sys import exc_info

from sqlalchemy.orm import attributes, loading
from sqlalchemy.orm.base import _DEFER_FOR_STATE, _SET_DEFERRED_EXPIRED, NEVER_SET, PASSIVE_NO_RESULT
from sqlalchemy.orm.loading import _decorate_polymorphic_switch, _populate_partial, _populate_full, _validate_version_id


cdef:
    frozenset _never_set = frozenset([NEVER_SET])
    frozenset _none_set = frozenset([None, NEVER_SET, PASSIVE_NO_RESULT])


cdef list fetchall(object query):
    """Return a list of results for a query."""
    cdef list process, rows

    context = query._compile_context()
    conn = query._get_bind_args(
        context,
        query._connection_from_session,
        close_with_result=True)
    cursor = conn.execute(context.statement, query._params)
    del conn

    context.runid = loading._new_runid()

    try:
        return cursor.fetchall()
    except Exception as err:
        cursor.close()
        exc_type, exc_value, exc_tb = exc_info()
        if err.__traceback__ is not exc_tb:
            raise err.with_traceback(exc_tb)
        raise err


def get_results(object query):
    """Return a list of lists for a query."""
    cdef list process, rows

    context = query._compile_context()
    conn = query._get_bind_args(
        context,
        query._connection_from_session,
        close_with_result=True)
    cursor = conn.execute(context.statement, query._params)
    query = context.query
    del conn

    context.runid = loading._new_runid()

    try:
        process = [query_entity.row_processor(query, context, cursor)[0]
                   for query_entity in query._entities]
        rows = cursor.fetchall()
        return [[proc(row) for proc in process]
                for row in rows]
    except Exception as err:
        cursor.close()
        exc_type, exc_value, exc_tb = exc_info()
        if err.__traceback__ is not exc_tb:
            raise err.with_traceback(exc_tb)
        raise err


def _instance_processor(
        mapper, context, result, path, adapter,
        only_load_props=None, refresh_state=None,
        polymorphic_discriminator=None,
        _polymorphic_from=None):
    """Produce a mapper level row processor callable
       which processes rows into mapped instances."""

    # note that this method, most of which exists in a closure
    # called _instance(), resists being broken out, as
    # attempts to do so tend to add significant function
    # call overhead.  _instance() is the most
    # performance-critical section in the whole ORM.

    pk_cols = mapper.primary_key

    if adapter:
        pk_cols = [adapter.columns[c] for c in pk_cols]

    identity_class = mapper._identity_class

    populators = defaultdict(list)

    props = mapper._prop_set
    if only_load_props is not None:
        props = props.intersection(
            mapper._props[k] for k in only_load_props)

    quick_populators = path.get(
        context.attributes, "memoized_setups", _none_set)

    for prop in props:
        if prop in quick_populators:
            # this is an inlined path just for column-based attributes.
            col = quick_populators[prop]
            if col is _DEFER_FOR_STATE:
                populators["new"].append(
                    (prop.key, prop._deferred_column_loader))
            elif col is _SET_DEFERRED_EXPIRED:
                # note that in this path, we are no longer
                # searching in the result to see if the column might
                # be present in some unexpected way.
                populators["expire"].append((prop.key, False))
            else:
                if adapter:
                    col = adapter.columns[col]
                getter = result._getter(col, False)
                if getter:
                    populators["quick"].append((prop.key, getter))
                else:
                    # fall back to the ColumnProperty itself, which
                    # will iterate through all of its columns
                    # to see if one fits
                    prop.create_row_processor(
                        context, path, mapper, result, adapter, populators)
        else:
            prop.create_row_processor(
                context, path, mapper, result, adapter, populators)

    propagate_options = context.propagate_options
    load_path = context.query._current_path + path \
        if context.query._current_path.path else path

    session_identity_map = context.session.identity_map

    cdef:
        bool populate_existing = context.populate_existing or mapper.always_refresh
        bool load_evt = bool(mapper.class_manager.dispatch.load)
        bool refresh_evt = bool(mapper.class_manager.dispatch.refresh)
        bool persistent_evt = bool(context.session.dispatch.loaded_as_persistent)
    if persistent_evt:
        loaded_as_persistent = context.session.dispatch.loaded_as_persistent
    instance_state = attributes.instance_state
    instance_dict = attributes.instance_dict
    session_id = context.session.hash_key
    version_check = context.version_check
    runid = context.runid

    if refresh_state:
        refresh_identity_key = refresh_state.key
        if refresh_identity_key is None:
            # super-rare condition; a refresh is being called
            # on a non-instance-key instance; this is meant to only
            # occur within a flush()
            refresh_identity_key = \
                mapper._identity_key_from_state(refresh_state)
    else:
        refresh_identity_key = None

    if mapper.allow_partial_pks:
        is_not_primary_key = _none_set.issuperset
    else:
        is_not_primary_key = _none_set.intersection

    def _instance(row):
        cdef:
            dict dict_
            bool isnew, currentload, loaded_instance
            tuple identitykey

        # determine the state that we'll be populating
        if refresh_identity_key:
            # fixed state that we're refreshing
            state = refresh_state
            instance = state.obj()
            dict_ = instance_dict(instance)
            isnew = state.runid != runid
            currentload = True
            loaded_instance = False
        else:
            # look at the row, see if that identity is in the
            # session, or we have to create a new one
            identitykey = (
                identity_class,
                tuple([row[column] for column in pk_cols])
            )

            instance = session_identity_map.get(identitykey)

            if instance is not None:
                # existing instance
                state = instance_state(instance)
                dict_ = instance_dict(instance)

                isnew = state.runid != runid
                currentload = not isnew
                loaded_instance = False

                if version_check and not currentload:
                    _validate_version_id(mapper, state, dict_, row, adapter)

            else:
                # create a new instance

                # check for non-NULL values in the primary key columns,
                # else no entity is returned for the row
                if is_not_primary_key(identitykey[1]):
                    return None

                isnew = True
                currentload = True
                loaded_instance = True

                instance = mapper.class_manager.new_instance()

                dict_ = instance_dict(instance)
                state = instance_state(instance)
                state.key = identitykey

                # attach instance to session.
                state.session_id = session_id
                session_identity_map._add_unpresent(state, identitykey)

        # populate.  this looks at whether this state is new
        # for this load or was existing, and whether or not this
        # row is the first row with this identity.
        if currentload or populate_existing:
            # full population routines.  Objects here are either
            # just created, or we are doing a populate_existing

            # be conservative about setting load_path when populate_existing
            # is in effect; want to maintain options from the original
            # load.  see test_expire->test_refresh_maintains_deferred_options
            if isnew and (propagate_options or not populate_existing):
                state.load_options = propagate_options
                state.load_path = load_path

            _populate_full(
                context, row, state, dict_, isnew, load_path,
                loaded_instance, populate_existing, <dict>populators)

            if isnew:
                if loaded_instance:
                    if load_evt:
                        state.manager.dispatch.load(state, context)
                    if persistent_evt:
                        loaded_as_persistent(context.session, state.obj())
                elif refresh_evt:
                    state.manager.dispatch.refresh(
                        state, context, only_load_props)

                if populate_existing or state.modified:
                    if refresh_state and only_load_props:
                        state._commit(dict_, only_load_props)
                    else:
                        state._commit_all(dict_, session_identity_map)

        else:
            # partial population routines, for objects that were already
            # in the Session, but a row matches them; apply eager loaders
            # on existing objects, etc.
            unloaded = state.unloaded
            isnew = state not in context.partials

            if not isnew or unloaded or populators["eager"]:
                # state is having a partial set of its attributes
                # refreshed.  Populate those attributes,
                # and add to the "context.partials" collection.

                to_load = _populate_partial(
                    context, row, state, dict_, isnew, load_path,
                    unloaded, <dict>populators)

                if isnew:
                    if refresh_evt:
                        state.manager.dispatch.refresh(
                            state, context, to_load)

                    state._commit(dict_, to_load)

        return instance

    if mapper.polymorphic_map and not _polymorphic_from and not refresh_state:
        # if we are doing polymorphic, dispatch to a different _instance()
        # method specific to the subclass mapper
        _instance = _decorate_polymorphic_switch(
            _instance, context, mapper, result, path,
            polymorphic_discriminator, adapter)

    return _instance


loading._instance_processor = _instance_processor
