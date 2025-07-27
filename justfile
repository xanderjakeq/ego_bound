ext := "-collection:ext=$HOME/dev/odin/ext/"
assets := "-collection:assets=./assets/"

run: build_atlas
    odin run ./src {{assets}} {{ext}}

build_atlas:
    ./atlas_builder

