# -*- coding: utf-8 -*-
# Сборка всех частей перевода acore_string
import importlib
T = {}
for _p in "abcdefgh":
    try:
        T.update(importlib.import_module("tr_strings_" + _p).T)
    except ImportError:
        pass
