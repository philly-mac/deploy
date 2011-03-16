Very simple tool to do deployments.

syntax

dep -e|--environment -r|--recipe -m|--method [-c|--config] [-d|--dry] [-q|--quiet]

    -e --environment:
        Allows you to specify the environment, which can be used to write different recipes for different environments

    -r --recipe:
        The ruby file with the methods that you want to execute

    -m --method:
        The method within the recipe that you want to execute

    -c --config:
        You can specify a custom configuration file that is in a non standard location

    -d --dry:
        Dry run. Show what will be done, but do not actually execute any commands

    -q --quiet:
        By default everything is very verbose, if you wish to quiet the output you can specify this option

