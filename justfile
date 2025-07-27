# collection := "-collection:libs=$HOME/dev/odin/ext/"
assets := "-collection:assets=./assets/"

# odin run . {{collection}}
run:
    odin run . {{assets}}

