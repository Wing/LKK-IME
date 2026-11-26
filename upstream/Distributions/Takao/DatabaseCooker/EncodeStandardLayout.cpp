// SPDX-License-Identifier: BSD-3-Clause
#include "Mandarin.h"

int main(int argc, char** argv)
{
    using namespace Formosa::Mandarin;
    std::string line;
    const auto* layout = BopomofoKeyboardLayout::StandardLayout();
    if (argc != 2) return 2;
    const std::string mode(argv[1]);
    if (mode != "encode" && mode != "standard") return 2;
    while (std::getline(std::cin, line)) {
        if (mode == "standard") {
            std::cout << layout->syllableFromKeySequence(line).absoluteOrderString() << '\n';
            continue;
        }
        std::string result;
        size_t start = 0;
        while (start < line.size()) {
            auto end = line.find(' ', start);
            result += BPMF::FromComposedString(line.substr(start, end == std::string::npos ? end : end - start)).absoluteOrderString();
            if (end == std::string::npos) break;
            start = end + 1;
        }
        std::cout << result << '\n';
    }
}
