ext := "-collection:ext=$HOME/dev/odin/ext/"
assets := "-collection:assets=./assets/"

dev: build_atlas
    odin run ./src {{assets}} {{ext}}

run:
    odin run ./src

build_atlas:
    ./atlas_builder

