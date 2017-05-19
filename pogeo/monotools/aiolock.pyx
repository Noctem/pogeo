# distutils: language = c++
# cython: language_level=3

cdef class AioLock:
    def __cinit__(self, loop):
        self._waiters = []
        self._loop = loop
        self.locked = False

    async def __aenter__(self):
        await self.acquire()

    async def __aexit__(self, exc_type, exc, tb):
        self.release()

    async def acquire(self):
        """Acquire a lock.

        This method blocks until the lock is unlocked, then sets it to
        locked and returns True.
        """
        if not self.locked and all(w.cancelled() for w in self._waiters):
            self.locked = True
            return True

        fut = self._loop.create_future()
        self._waiters.append(fut)
        try:
            await fut
            self.locked = True
            return True
        finally:
            self._waiters.remove(fut)

    async def wait(self):
        """Wait for a lock.

        This method blocks until the lock is unlocked, then returns True.
        """
        if not self.locked and all(w.cancelled() for w in self._waiters):
            return True

        fut = self._loop.create_future()
        self._waiters.append(fut)
        try:
            return await fut
        finally:
            self._waiters.remove(fut)

    cdef void release(self):
        """Release a lock.

        When the lock is locked, reset it to unlocked, and return.
        If any other coroutines are blocked waiting for the lock to become
        unlocked, allow exactly one of them to proceed.

        There is no return value.
        """
        self.locked = False
        for fut in self._waiters:
            if not fut.done():
                fut.set_result(True)
