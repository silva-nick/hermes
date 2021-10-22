/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include "hermes/Platform/Intl/PlatformIntl.h"

#import <Foundation/Foundation.h>

namespace hermes {
namespace platform_intl {
namespace {
NSString *bestAvailableLocale(NSString *locale, NSArray *availableLocales) {
  // Implementer note: This method corresponds roughly to
  // https://tc39.es/ecma402/#sec-bestavailablelocale}
  // 1. Let candidate be locale
  NSString *candidate = locale;

  // 2. Repeat
  while (true) {
    // a. If availableLocales contains an element equal to candidate, return
    // candidate.
    if ([availableLocales containsObject:candidate]) {
      return candidate;
    }

    // b. Let pos be the character index of the last occurrence of "-" (U+002D)
    // within candidate.
    NSUInteger pos =
        [candidate rangeOfString:@"-" options:NSBackwardsSearch].location;
    // ...If that character does not occur, return undefined.
    if (pos < 0ul) {
      return @"";
    }

    // c. If pos ≥ 2 and the character "-" occurs at index pos-2 of candidate,
    // decrease pos by 2.
    if (pos >= 2ul &&
        [@"-" isEqualToString:[candidate substringWithRange:NSMakeRange(
                                                                pos - 2, 1)]]) {
      pos -= 2;
    }
    // d. Let candidate be the substring of candidate from position 0,
    // inclusive, to position pos, exclusive.
    candidate = [candidate substringToIndex:pos];
  }
}
}
vm::CallResult<std::vector<std::u16string>> getCanonicalLocales(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales) {
  return std::vector<std::u16string>{u"fr-FR", u"es-ES"};
}

// Implementer note: This method corresponds roughly to
// https://tc39.es/ecma402/#sup-string.prototype.tolocalelowercase
vm::CallResult<std::u16string> toLocaleLowerCase(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const std::u16string &str) {
  NSString *nsStr = u16StringToNSString(str);

  // 3. Let requestedLocales be ? CanonicalizeLocaleList(locales).
  vm::CallResult<std::vector<std::u16string>> requestedLocales =
      getCanonicalLocales(runtime, locales);
  // getcano doesnt throw so should this be removed?
  if (LLVM_UNLIKELY(requestedLocales == llvh::ExecutionStatus::EXCEPTION)) {
    return llvh::ExecutionStatus::EXCEPTION;
  }

  // 4. If requestedLocales is not an empty List, then
  std::u16string requestedLocale;
  if (!requestedLocales->empty()) {
    // a. Let requestedLocale be requestedLocales[0].
    std::vector<std::u16string> val = requestedLocales.getValue();
    requestedLocale = val[0];
  } else { // 5. Else,
    // a. Let requestedLocale be DefaultLocale().
    return nsStringToU16String(
        [nsStr lowercaseStringWithLocale:[NSLocale currentLocale]]);
  }
  // 6. Let noExtensionsLocale be the String value that is requestedLocale with
  // any Unicode locale extension sequences (6.2.1) removed.
  // TODO

  // 7. Let availableLocales be a List with language tags that includes the
  // languages for which the Unicode Character Database contains language
  // sensitive case mappings. Implementations may add additional language tags
  // if they support case mapping for additional locales.
  NSArray<NSString *> *availableLocales = [NSLocale availableLocaleIdentifiers];

  // 8. Let locale be BestAvailableLocale(availableLocales, noExtensionsLocale).
  NSString *NSBestLocale = u16StringToNSString(requestedLocale);
  // No matching function for call to 'bestAvailableLocale'???
  auto *bestLocale = bestAvailableLocale(availableLocales, NSBestLocale);
  // 9. If locale is undefined, let locale be "und".
  if (bestLocale == nil) {
    bestLocale = @"und";
  }

  // 10. Let cpList be a List containing in order the code points of S as
  // defined in es2022, 6.1.4, starting at the first element of S.
  // 11. Let cuList be a List where the elements are the result of a lower case
  // transformation of the ordered code points in cpList according to the
  // Unicode Default Case Conversion algorithm or an implementation-defined
  // conversion algorithm. A conforming implementation's lower case
  // transformation algorithm must always yield the same cpList given the same
  // cuList and locale.
  // 12. Let L be a String whose elements are the UTF-16 Encoding (defined in
  // es2022, 6.1.4) of the code points of cuList.
  NSString *L = u16StringToNSString(bestLocale);
  // 13. Return L.
  return nsStringToU16String([nsStr
      lowercaseStringWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:L]]);
}

// Implementer note: This method corresponds roughly to
// https://tc39.es/ecma402/#sup-string.prototype.tolocaleuppercase
vm::CallResult<std::u16string> toLocaleUpperCase(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const std::u16string &str) {
  return std::u16string(u"uppered");
}

struct Collator::Impl {
  std::u16string locale;
};

Collator::Collator() : impl_(std::make_unique<Impl>()) {}
Collator::~Collator() {}

vm::CallResult<std::vector<std::u16string>> Collator::supportedLocalesOf(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  return std::vector<std::u16string>{u"en-CA", u"de-DE"};
}

vm::ExecutionStatus Collator::initialize(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  impl_->locale = u"en-US";
  return vm::ExecutionStatus::RETURNED;
}

Options Collator::resolvedOptions() noexcept {
  Options options;
  options.emplace(u"locale", Option(impl_->locale));
  options.emplace(u"numeric", Option(false));
  return options;
}

double Collator::compare(
    const std::u16string &x,
    const std::u16string &y) noexcept {
  return x.compare(y);
}

struct DateTimeFormat::Impl {
  std::u16string locale;
};

DateTimeFormat::DateTimeFormat() : impl_(std::make_unique<Impl>()) {}
DateTimeFormat::~DateTimeFormat() {}

vm::CallResult<std::vector<std::u16string>> DateTimeFormat::supportedLocalesOf(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  return std::vector<std::u16string>{u"en-CA", u"de-DE"};
}

vm::ExecutionStatus DateTimeFormat::initialize(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  impl_->locale = u"en-US";
  return vm::ExecutionStatus::RETURNED;
}

Options DateTimeFormat::resolvedOptions() noexcept {
  Options options;
  options.emplace(u"locale", Option(impl_->locale));
  options.emplace(u"numeric", Option(false));
  return options;
}

std::u16string DateTimeFormat::format(double jsTimeValue) noexcept {
  auto s = std::to_string(jsTimeValue);
  return std::u16string(s.begin(), s.end());
}

std::vector<std::unordered_map<std::u16string, std::u16string>>
DateTimeFormat::formatToParts(double jsTimeValue) noexcept {
  std::unordered_map<std::u16string, std::u16string> part;
  part[u"type"] = u"integer";
  // This isn't right, but I didn't want to do more work for a stub.
  std::string s = std::to_string(jsTimeValue);
  part[u"value"] = {s.begin(), s.end()};
  return std::vector<std::unordered_map<std::u16string, std::u16string>>{part};
}

struct NumberFormat::Impl {
  std::u16string locale;
};

NumberFormat::NumberFormat() : impl_(std::make_unique<Impl>()) {}
NumberFormat::~NumberFormat() {}

vm::CallResult<std::vector<std::u16string>> NumberFormat::supportedLocalesOf(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  return std::vector<std::u16string>{u"en-CA", u"de-DE"};
}

vm::ExecutionStatus NumberFormat::initialize(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  impl_->locale = u"en-US";
  return vm::ExecutionStatus::RETURNED;
}

Options NumberFormat::resolvedOptions() noexcept {
  Options options;
  options.emplace(u"locale", Option(impl_->locale));
  options.emplace(u"numeric", Option(false));
  return options;
}

std::u16string NumberFormat::format(double number) noexcept {
  auto s = std::to_string(number);
  return std::u16string(s.begin(), s.end());
}

std::vector<std::unordered_map<std::u16string, std::u16string>>
NumberFormat::formatToParts(double number) noexcept {
  std::unordered_map<std::u16string, std::u16string> part;
  part[u"type"] = u"integer";
  // This isn't right, but I didn't want to do more work for a stub.
  std::string s = std::to_string(number);
  part[u"value"] = {s.begin(), s.end()};
  return std::vector<std::unordered_map<std::u16string, std::u16string>>{part};
}

} // namespace platform_intl
} // namespace hermes
