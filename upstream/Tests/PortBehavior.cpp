// SPDX-License-Identifier: BSD-3-Clause
// Tests the original loader, context and candidate panel without registering an IME.
#define OV_USE_SQLITE
#include <PlainVanilla/PlainVanilla.h>
#include "OVIMMandarinPackage.h"
#include "OVIMGenericPackage.h"
#include "BPMFUserPhraseHelper.h"
#include <memory>
#include <stdexcept>

using namespace OpenVanilla;

class TestPolicy : public PVLoaderPolicy {
    std::string root;
public:
    explicit TestPolicy(const std::string& path) : PVLoaderPolicy({}), root(path) {}
    const OVPathInfo modulePackagePathInfoFromPath(const std::string&) override {
        return {root, root, root};
    }
    const std::string propertyListPathFromIdentifier(const std::string& id) override {
        return root + "/" + id + ".plist";
    }
    const std::string propertyListPathForLoader() override {
        return root + "/loader.plist";
    }
};

static void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

static bool press(PVLoaderContext& context, unsigned int key, unsigned int modifiers = 0) {
    OVKey event(new PVKeyImpl(key, modifiers));
    return context.handleKeyEvent(&event);
}

static void setupUserDB(OVSQLiteConnection& db) {
    require(db.execute("CREATE TABLE user_unigrams(qstring, current, probability, backoff)") == SQLITE_OK, "User unigram schema failed");
    require(db.execute("CREATE TABLE user_bigram_cache(qstring, previous, current, probability)") == SQLITE_OK, "User bigram schema failed");
    require(db.execute("CREATE TABLE user_candidate_override_cache(qstring, current)") == SQLITE_OK, "User override schema failed");
}

static void testPhraseRoundTrip(const std::string& root) {
    using Manjusri::BPMFUserPhraseHelper;
    std::unique_ptr<OVSQLiteConnection> from(OVSQLiteConnection::Open(":memory:"));
    std::unique_ptr<OVSQLiteConnection> to(OVSQLiteConnection::Open(":memory:"));
    require(from && to, "User phrase test database failed");
    setupUserDB(*from);
    setupUserDB(*to);
    auto q = BPMFUserPhraseHelper::QString("ㄋㄧˇ,ㄏㄠˇ");
    require(from->execute("INSERT INTO user_unigrams VALUES(%Q,'你好',-1,0)", q.first.c_str()) == SQLITE_OK, "Synthetic phrase insert failed");
    require(from->execute("INSERT INTO user_candidate_override_cache VALUES('test','你好')") == SQLITE_OK, "Synthetic cache insert failed");
    const std::string path = root + "/phrases.txt";
    require(BPMFUserPhraseHelper::Export(from.get(), path), "Phrase export failed");
    require(BPMFUserPhraseHelper::Import(to.get(), path), "Phrase import failed");
    std::unique_ptr<OVSQLiteStatement> phrase(to->prepare("SELECT current FROM user_unigrams"));
    require(phrase && phrase->step() == SQLITE_ROW && std::string(phrase->textOfColumn(0)) == "你好", "Phrase round trip mismatch");
    std::unique_ptr<OVSQLiteStatement> cache(to->prepare("SELECT current FROM user_candidate_override_cache"));
    require(cache && cache->step() == SQLITE_ROW && std::string(cache->textOfColumn(0)) == "你好", "Learning cache round trip mismatch");
}

int main(int argc, char** argv) {
    try {
        require(argc == 3, "Expected a test database and isolated writable directory");
        TestPolicy policy(argv[2]);
        std::unique_ptr<OVSQLiteDatabaseService> db(OVSQLiteDatabaseService::Create(argv[1]));
        require(bool(db), "Could not load database");
        PVLoaderService service("zh_TW", nullptr, db.get());
        OVPathInfo paths = policy.modulePackagePathInfoFromPath("");
        PVStaticModulePackageLoadingSystem packages(paths, true);
        auto* mandarin = new OVIMMandarinPackage;
        require(mandarin->initialize(&paths, &service), "Mandarin package failed");
        packages.addInitializedPackage("OVIMMandarinPackage", mandarin);
        auto* generic = new OVIMGenericPackage;
        require(generic->initialize(&paths, &service), "Generic package failed");
        packages.addInitializedPackage("OVIMGenericPackage", generic);
        PVLoader loader(&policy, &service, {&packages});
        for (const auto* id : {"SmartMandarin", "TraditionalMandarin", "Generic-cj-cin", "Generic-simplex-cin"})
            require(!loader.isFailedModule(id), "An input mode failed to initialize");
        loader.setPrimaryInputMethod("SmartMandarin");
        std::unique_ptr<PVLoaderContext> context(loader.createContext());
        context->activate();
        for (char key : std::string("su3cl3")) require(press(*context, key), "Bopomofo key not handled");
        require(context->composingText()->composedText() == "你好", "Expected 你好");
        require(press(*context, OVKeyCode::Return), "Return not handled");
        require(context->composingText()->composedCommittedText() == "你好", "Commit failed");
        context->composingText()->finishCommit();

        for (char key : std::string("g4")) require(press(*context, key), "Bopomofo key not handled");
        require(press(*context, OVKeyCode::Down), "Candidate key not handled");
        auto* panel = context->candidateService()->accessVerticalCandidatePanel();
        require(panel->isInControl() && panel->pageCount() > 1, "Expected multiple candidate pages");
        size_t firstPageCount = panel->currentPageCandidateCount();
        for (size_t i = 0; i < firstPageCount; ++i) require(press(*context, OVKeyCode::Down), "Down not handled");
        require(panel->currentPage() == 1 && panel->currentHightlightIndex() == 0, "Down must cross to the next page");
        require(press(*context, OVKeyCode::Up), "Up not handled");
        require(panel->currentPage() == 0 && panel->currentHightlightIndex() == firstPageCount - 1, "Up must cross to the previous page");
        context->clear();

        for (const auto& item : std::vector<std::pair<char, std::string>>{{':', "："}, {'<', "，"}, {'\'', "、"}, {'"', "；"}}) {
            require(press(*context, item.first, item.first == '\'' ? 0 : OVKeyMask::Shift), "Punctuation key not handled");
            auto* punctuationPanel = context->candidateService()->accessVerticalCandidatePanel();
            std::string value = context->composingText()->composedText();
            if (punctuationPanel->isInControl()) {
                require(press(*context, OVKeyCode::Return), "Punctuation selection failed");
                value = context->composingText()->composedText();
            }
            if (value.empty()) value = context->composingText()->composedCommittedText();
            if (value != item.second) std::cerr << "Punctuation " << item.first << ": expected " << item.second << ", got " << value << '\n';
            require(value == item.second, "Expected upstream full-width punctuation");
            context->clear();
        }
        context->deactivate();
        context.reset();
        for (const auto* id : {"TraditionalMandarin", "Generic-cj-cin", "Generic-simplex-cin"}) {
            loader.setPrimaryInputMethod(id);
            context.reset(loader.createContext());
            context->activate();
            if (std::string(id) == "TraditionalMandarin") {
                for (char key : std::string("su3")) require(press(*context, key), "Traditional phonetic key not handled");
            } else {
                require(press(*context, 'a'), "Cangjie/Simplex key not handled");
                require(press(*context, OVKeyCode::Space), "Cangjie/Simplex space not handled");
            }
            auto* selection = context->candidateService()->accessVerticalCandidatePanel();
            require(selection->isInControl() || !context->composingText()->composedText().empty() || context->composingText()->isCommitted(), "Expected candidate or committed text in an input mode");
            context->deactivate();
            context.reset();
        }
        testPhraseRoundTrip(argv[2]);
        std::cout << "PASS: original four input modes, commit, cross-page selection, full-width punctuation and user phrase round trip\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
