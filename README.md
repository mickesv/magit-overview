magit-overview
==============

Emacs magit: status overview over all reachable git repositories

Usage:
- put this file in your emacs path
- (require 'magit-overview)
- Start it with "M-x magit-overview".

I have tested it on MacOS X (2014-11-26). The open commands may not work e.g. on Windows, since I am "cheating" a bit when finding out the path to the selected repository.

---
Very brief documentation:

(magit-overview-mode)

Major mode for magit-overview-mode.

Special commands:

|key   | binding |
|---|---|
|d	    | magit-overview-open-dired |
|g		  | magit-overview-redisplay |
|n		  | magit-overview-find-next-dirty |
|p		  | magit-overview-find-prev-dirty |
|q		  | magit-overview-quit-window |
|return	|  magit-overview-open-magit |

