pybabel extract -F babelrc -k text -k LineEdit/placeholder_text -k tr -o locales/translation.pot .
msgmerge --update --backup=simple --suffix=.back locales/fr.po locales/translation.pot
msgmerge --update --backup=simple --suffix=.back locales/en.po locales/translation.pot
