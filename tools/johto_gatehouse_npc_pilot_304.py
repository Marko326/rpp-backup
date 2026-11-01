#!/usr/bin/env python3
"""Compatibility shim: the current Ecruteak gatehouse NPC audit is REF-305."""
from johto_gatehouse_npc_pilot_305 import audit, fault_tests, main

if __name__ == "__main__":
    raise SystemExit(main())
