import asyncio
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.environ.setdefault("NPS_BASE_DIR", HERE)

import bridge_core
import msm_protocol
from fastapi.responses import JSONResponse


async def _nps_health():
    return JSONResponse({"nps_server": True})


bridge_core.app.add_api_route("/nps_health", _nps_health, methods=["GET"])
bridge_core.app.router.routes.insert(0, bridge_core.app.router.routes.pop())

_inner_build_raw_frame = msm_protocol.build_raw_frame


def _stringify_costumes_owned(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "costumes_owned" and isinstance(value, list):
                node[key] = __import__("json").dumps(value, separators=(",", ":"))
            else:
                _stringify_costumes_owned(value)
    elif isinstance(node, list):
        for item in node:
            _stringify_costumes_owned(item)


def _build_raw_frame(command, payload):
    if isinstance(payload, (dict, list)):
        _stringify_costumes_owned(payload)
    return _inner_build_raw_frame(command, payload)


msm_protocol.build_raw_frame = _build_raw_frame


def _account_entry(account):
    return {
        "type": "email",
        "username": account["username"],
        "userName": account["username"],
        "email": account["email"],
        "can_bind_to": True,
        "can_create": True,
        "auto_create": False,
    }


def _sync_active_save():
    try:
        name = str(bridge_core.forced_account().get("username", "")).strip()
        if name and (bridge_core.SFS_PLAYERS_DIR / (name + ".json")).exists():
            bridge_core.set_active_username(name)
    except Exception:
        pass


async def _existing_accounts():
    _sync_active_save()
    account = bridge_core.forced_account()
    entry = _account_entry(account)
    return JSONResponse(
        {
            "ok": True,
            "success": True,
            "status": "ok",
            "found": True,
            "existing_account": True,
            "account_exists": True,
            "create_account": False,
            "connectionError": False,
            "can_create": True,
            "auto_create": False,
            "can_bind_to": ["email"],
            "isAvailable": True,
            "existing_accounts": [entry],
            "accounts": [entry],
            "login_types": ["email"],
        }
    )


def install_existing_accounts():
    paths = ("/auth/api/existing_accounts", "/auth/api/existing_accounts/")
    app = bridge_core.app
    app.router.routes = [
        r for r in app.router.routes if getattr(r, "path", None) not in paths
    ]
    before = len(app.router.routes)
    for p in paths:
        app.add_api_route(p, _existing_accounts, methods=["GET", "POST"])
    app.router.routes = app.router.routes[before:] + app.router.routes[:before]


install_existing_accounts()

if __name__ == "__main__":
    _sync_active_save()
    asyncio.run(bridge_core.main())
