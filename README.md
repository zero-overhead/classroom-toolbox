NAME
====

App:Classroom::Toolbox - Simple Classroom Management Toolbox.

DESCRIPTION
===========

Classroom::Toolbox is a collection of simple scripts teachers need to manage a classroom.

Tools
=====

```bash
crtb-tool-name --help
```

```bash
crtb-init-folders

crtb-create-placement
crtb-display-placement

crtb-create-groups
crtb-display-groups

crtb-pick-group-from-placement-file
crtb-pick-group-from-class-file

crtb-timer
```

CONFIGURATION
=============

Set defaults to be used by tools - if you do not like to use the corresponding command line parameters.

This usually won't change much - perhaps use direnv to set all of these variables automatically
```bash
export CRTB_PICTURE_FOLDER=pictures
export CRTB_PLACEMENTS_FOLDER=placements
export CRTB_GRADES_FOLDER=grades
export CRTB_GROUP_FOLDER=groups
```

Before creating a placement

```bash
export CRTB_CLASS_FILE=classes/demo-class-large
export CRTB_ROOM_FILE=rooms/demo-room-1

export CRTB_MAX_DISPLAY_NAME_WIDTH=20
```

After you created a placement, grouping or grading you might want to set

```bash
export CRTB_PLACEMENT_FILE=placements/demo-placement
export CRTB_GROUP_FILE=groups/demo-grouping
export CRTB_GRADE_FILE=grades/demo-grading
```

```bash
export CRTB_GROUP_SIZE=1
export CRTB_PRIMARY_GROUP_SIZE=2
export CRTB_SECONDARY_GROUP_SIZE=3
```

**classes/**

--class-file= or CRTB_CLASS=

**rooms/**

--room-file= or CRTB_ROOM=

**pictures/**

--picture-folder= or CRTB_PICTURE_FOLDER=

**placements/**

--placement-file= or export CRTB_PLACENMENT=placements/demo-placement

**grades**

t.b.d

SETUP
=====

```bash
git clone https://github.com/zero-overhead/classroom-toolbox
cd classroom-toolbox
zef install .
```

**imagemagick**

required for showing pictures on Linux, install

```bash
brew install imagemagick
```

or e.g.

```bash
nix-shell -p imagemagick
```

AUTHOR
======

rcmlz <19784049+rcmlz@users.noreply.github.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2024 rcmlz

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

