# Emergency hotfix with active development

Branch the minimum fix from the latest production tag, validate and release it
through the protected hotfix workflow, then merge it into `develop` and active
experiments deliberately. Never replace an experiment with a production AddOns
folder or branch. The sync audit must identify branches missing the hotfix.
