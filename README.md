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

    -M --methods:
        Displays all the methods that can be executed with the -m switch. Must be used with -r as only the methods
        for that recipe will be displayed

    -R --revert:
        Allows you to revert to any previous release. Displays a list of all the archived releases and allows you to
        choose which to switch to

    -p --parameter:
        Allows you to pass a comma separated list of key=value pairs to be used in the app
        E.g. "TEST1=test1,TEST2=test2"

examples

This will execute the deploy method in the RailsDataMapper class located in the lib/deploy/recipes folder if it exists

    dep -r production -r rails_data_mapper -m deploy

This will list the methods that are available to execute from the RailsDataMapper class

    dep -r rails_data_mapper -M

This will show what will happen when the deploy method is executed in the RailsDataMapper class, but will not actually do anything

    dep -r production -r rails_data_mapper -m deploy -d
