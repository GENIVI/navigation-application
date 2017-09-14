# list of source files containing strings for translation
lupdate_only { # that way those files will be skipped by C++ compiler
    SOURCES = ../qml/*.qml 
}

# list of language files that will store translated strings for every language we want
TRANSLATIONS = 	eng_USA_Latn.ts \
               	jpn_JPN_Hrkt.ts \
		kor_KOR_Hang.ts \
		deu_DEU_Latn.ts \
		fra_FRA_Latn.ts

