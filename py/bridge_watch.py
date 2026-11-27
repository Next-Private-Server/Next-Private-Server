import asyncio
import itertools
import mmap
import struct


class RequestWatch:
    def __init__(self):
        self.page = None
        self.ids = itertools.count(1)
        self.pending = {}
        self.http = 0
        self.sequence = 0
        self.skipped_runs = 0

    def open(self, path):
        self.close()
        with open(path, "w+b") as file:
            file.truncate(84)
            self.page = mmap.mmap(file.fileno(), 84)
        self.publish()

    def close(self):
        if self.page is not None:
            self.page.close()
        self.page = None
        self.pending.clear()
        self.http = 0
        self.skipped_runs = 0

    def publish(self):
        self.sequence = (self.sequence + 2) & 0x7FFFFFFE
        struct.pack_into(">I", self.page, 0, self.sequence | 1)
        oldest = next(iter(self.pending), 0)
        label = self.pending[oldest][1] if oldest else b""
        struct.pack_into(
            ">IIII64s",
            self.page,
            4,
            self.http,
            len(self.pending) - self.http,
            oldest,
            self.skipped_runs,
            label,
        )
        struct.pack_into(">I", self.page, 0, self.sequence)

    def begin(self, label, http=False):
        if self.page is None:
            return None
        token = next(self.ids) % 0x7FFFFFFF + 1
        self.pending[token] = (http, label)
        self.http += int(http)
        self.publish()
        return token

    def finish(self, token):
        if token in self.pending:
            self.http -= int(self.pending.pop(token)[0])
            self.publish()


watch = RequestWatch()


class ObservedQueue(asyncio.Queue):
    def __init__(self):
        super().__init__()
        self.tokens = set()
        self.without_reply = 0

    def record_result(self, replied):
        if watch.page is None:
            return
        self.without_reply = 0 if replied else self.without_reply + 1
        if self.without_reply == 8:
            watch.skipped_runs += 1
            watch.publish()

    def put_nowait(self, event):
        data = event.get("bytes")
        if data and len(data) >= 10 and data[0] == 0:
            size = data[9]
            if 0 < size <= len(data) - 10 and data[10 : 10 + size] != b"alive":
                name = data[10 : 10 + size]
                label = name if name.replace(b"_", b"").isalnum() else b"gameplay"
                token = watch.begin(label)
                if token is not None:
                    self.tokens.add(token)
                    event["nps_request"] = token
        super().put_nowait(event)

    def finish(self, token):
        self.tokens.discard(token)
        watch.finish(token)

    def clear_pending(self):
        for token in self.tokens:
            watch.finish(token)
        self.tokens.clear()


def observe_http(app):
    async def serve(scope, receive, send):
        if scope["type"] != "http" or scope["path"] == "/nps_server_config":
            return await app(scope, receive, send)
        token = watch.begin(
            scope["method"].encode("ascii", errors="replace"), http=True
        )
        try:
            return await app(scope, receive, send)
        finally:
            watch.finish(token)

    return serve
