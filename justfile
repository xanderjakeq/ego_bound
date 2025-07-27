ext := "-collection:ext=$HOME/dev/odin/ext/"
assets := "-collection:assets=./assets/"

run:
    odin run ./src {{assets}} {{ext}}

build_atlas:
    ./atlas_builder

