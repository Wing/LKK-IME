# Third-party notices

LKK-IME ports the original Yahoo! KeyKey 1.1.2528 macOS architecture; it is not an official Yahoo product.

| Component | Source | License |
| --- | --- | --- |
| Yahoo! KeyKey (macOS loader, UI, preferences, phrase editor, modules) | [YahooArchive/KeyKey](https://github.com/YahooArchive/KeyKey), commit `81e05f070c070af65cac21e8da28ca4ff2d58905` | BSD-3-Clause, original per-file notices |
| OpenVanilla, Formosa, PlainVanilla, Manjusri, Graphene and related code | Same source release | MIT and BSD-style per-file notices, original copyrights retained |
| Traditional Bopomofo extended table | `upstream/DataTables/bpmf-ext.cin` | Public domain as declared in its header |
| Original Cangjie 3 / Simplex, punctuation and correction tables | Yahoo! KeyKey source release, original CIN provenance retained | BSD-3-Clause release; Cangjie/Simplex based on opendesktop.org.tw tables, merged and extended by yylin and b6s |
| Replacement language model | [McBopomofo](https://github.com/openvanilla/McBopomofo), pinned by `Resources/data-sources.json` | MIT plus libtabe BSD attribution |
| Character and phrase conversion dictionaries | [OpenCC](https://github.com/BYVoid/OpenCC), `ver.1.1.9` (`556ed22496d650bd0b13b6c163be9814637970ae`) | Apache-2.0 |
| SQLite, InputMethodKit, Foundation, AppKit and other macOS frameworks | macOS SDK | System dependencies; not redistributed |

The source and binary distribution include the original BSD-3-Clause notice, consolidated source copyright and license notices, McBopomofo MIT, libtabe COPYING, and OpenCC Apache-2.0 in `Licenses/`. The original `upstream/COPYING` and file headers remain authoritative for individual source files.

The McBopomofo-derived model is generated using the original Formosa encoder; its published frequency and reading data is pinned and verified, with no original Yahoo or Sinica corpus. The model has unigrams but no static bigrams. The associated-phrase table is derived from the same public vocabulary. The original punctuation table is retained without layout changes.

OpenCC text dictionaries are vendored unchanged in `data/opencc/`; the build converts them to the original CIN and C array formats. Those generated outputs carry a modification notice and are not the original KeyKey or Perl-derived conversion tables.

Excluded: Yahoo branding images, old compiled binaries, CEROD/SEE, Apple DotMacKit, old installer/updater, retired tracker and signed-module keys, the old language model and corpus, and the Yahoo/Wikipedia-derived phrase-conversion table.
