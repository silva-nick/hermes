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
NSString *u16StringToNSString(std::u16string src) {
  auto size = src.size();
  const auto *cString = (const unichar *)src.c_str();
  return [NSString stringWithCharacters:cString length:size];
}
std::u16string nsStringToU16String(NSString *src) {
  auto size = src.length;
  std::u16string result;
  result.resize(size);
  [src getCharacters:(unichar *)&result[0] range:NSMakeRange(0, size)];
  return result;
}
std::vector<std::u16string> nsStringArrayToU16StringArray(const NSArray<NSString *> *array) {
  auto size = [array count];
  std::vector<std::u16string> result;
  result.reserve(size);
  for (size_t i = 0; i < size; i++) {
    result[i] = nsStringToU16String(array[i]);
  }
  return result;
}
NSArray<NSString *> *u16StringArrayToNSStringArray(const std::vector<std::u16string> &array) {
  auto size = array.size();
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: size];
  for (size_t i = 0; i < size; i++) {
    result[i] = u16StringToNSString(array[i]);
  }
  return result;
}
}

// Implementation of https://tc39.es/ecma402/#sec-canonicalizelocalelist
vm::CallResult<std::vector<std::u16string>> canonicalizeLocaleList(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales) {
  // 1. If locales is undefined, then
  //   a. Return a new empty List
  // Not needed, this validation occurs closer to VM in 'normalizeLocales'.
  // 2. Let seen be a new empty List.
  std::vector<std::u16string> seen;
  // 3. If Type(locales) is String or Type(locales) is Object and locales has an
  // [[InitializedLocale]] internal slot, then
  // 4. Else
  // We don't yet support Locale object -
  // https://tc39.es/ecma402/#locale-objects As of now, 'locales' can only be a
  // string list/array. Validation occurs in normalizeLocaleList, so this
  // function just takes a vector of strings.
  // 5. Let len be ? ToLength(? Get(O, "length")).
  // 6. Let k be 0.
  // 7. Repeat, while k < len
  for (std::u16string locale : locales) {
    // TODO - BCP 47 tag validation
    // 7.c.vi. Let canonicalizedTag be CanonicalizeUnicodeLocaleId(tag).
    auto *localeNSString = u16StringToNSString(locale);
    NSString *canonicalizedTagNSString =
        [NSLocale canonicalLocaleIdentifierFromString:localeNSString];
    auto canonicalizedTag = nsStringToU16String(canonicalizedTagNSString);
    // 7.c.vii. If canonicalizedTag is not an element of seen, append
    // canonicalizedTag as the last element of seen.
    if (std::find(seen.begin(), seen.end(), canonicalizedTag) == seen.end()) {
      seen.push_back(std::move(canonicalizedTag));
    }
  }
  return seen;
}

// https://tc39.es/ecma402/#sec-canonicalizelocalelist
vm::CallResult<std::vector<std::u16string>> getCanonicalLocales(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales) {
  return canonicalizeLocaleList(runtime, locales);
}

vm::CallResult<std::u16string> toLocaleLowerCase(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const std::u16string &str) {
  return std::u16string(u"lowered");
}
vm::CallResult<std::u16string> toLocaleUpperCase(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const std::u16string &str) {
  return std::u16string(u"uppered");
}

// Implementation of
// https://tc39.es/ecma402/#sec-getoption
vm::CallResult<Option> getOption(
    const Options &options,
    const std::u16string property,
    const std::u16string type,
    const std::vector<std::u16string> values,
    const Option &fallback) {
  // 1. Assert type(options) is object
  // 2. Let value be ? Get(options, property).
  auto value = options.find(property);
  // 3. If value is undefined, return fallback.
  if (value == options.end()) {
    return fallback;
  }
  // 4. Assert: type is "boolean" or "string".
  // 5. If type is "boolean", then
  if (type == u"boolean") {
    if(!value->second.isBool()) {
      // TODO: in what layer do we call into runtime to throw exceptions
      //return runtime->raiseRangeError(u"Boolean option expected but not found");
    }
    // a. Set value to ! ToBoolean(value).
  }
  // 6. If type is "string", then
  if (type == u"string") {
    if(!value->second.isString()) {
      //return runtime->raiseRangeError(u"String option expected but not found");
    }
    // a. Set value to ? ToString(value).
  }
  // 7. If values is not undefined and values does not contain an element equal to value, throw a RangeError exception.
  if (!values.empty() && llvh::find(values, value->second) == values.end()) {
    return vm::ExecutionStatus::EXCEPTION;
  }
  // 8. Return value.
  return value->second;
}

// Implementation of
// https://tc39.es/ecma402/#sec-lookupsupportedlocales
std::vector<std::u16string> lookupSupportedLocales(
    const std::vector<std::u16string> &availableLocales,
    const std::vector<std::u16string> &requestedLocales) {
  // 1. Let subset be a new empty List.
  std::vector<std::u16string> subset;
  // 2. For each element locale of requestedLocales, do
  for (const std::u16string &locale: requestedLocales) {
    // a. Let noExtensionsLocale be the String value that is locale with any Unicode locale extension sequences removed.
    //std::u16string noExtensionsLocale = toNoExtensionsLocale(locale);
    // b. Let availableLocale be BestAvailableLocale(availableLocales, noExtensionsLocale).
    //std::u16string availableLocale = bestAvailableLocale(availableLocales, noExtensionsLocale);
    // c. If availableLocale is not undefined, append locale to the end of subset.
    // if (!availableLocale.empty()) { subset.push_back(locale); }
  }

  // 3. Return subset.
  return subset;
}

// Implementation of
// https://tc39.es/ecma402/#sec-supportedlocales
vm::CallResult<std::vector<std::u16string>> supportedLocales(
    const std::vector<std::u16string> availableLocales,
    const std::vector<std::u16string> requestedLocales,
    const Options &options) {
  // 1. Set options to ? CoerceOptionsToObject(options).
  // 2. Let matcher be ? GetOption(options, "localeMatcher", "string", « "lookup", "best fit" », "best fit").
  std::vector<std::u16string> vectorForMatcher = {u"lookup", u"best fit"};
  vm::CallResult<std::u16string> matcher = getOption(options, u"localeMatcher", u"string", vectorForMatcher, u"best fit").getValue().getString();
  if (LLVM_UNLIKELY(matcher == vm::ExecutionStatus::EXCEPTION)) {
    return vm::ExecutionStatus::EXCEPTION;
  }
  
  std::vector<std::u16string> supportedLocales;
  // 3. If matcher is "best fit", then
  if (matcher.getValue() == u"best fit") {
    // a. Let supportedLocales be BestFitSupportedLocales(availableLocales, requestedLocales).
    // TODO: Is bestFitSupportedLocales required?
    supportedLocales = lookupSupportedLocales(availableLocales, requestedLocales);
  } else { // 4. Else,
    // a. Let supportedLocales be LookupSupportedLocales(availableLocales, requestedLocales).
    supportedLocales = lookupSupportedLocales(availableLocales, requestedLocales);
  }
  
  // 5. Return CreateArrayFromList(supportedLocales).
  return supportedLocales;
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

// Implementation of
// https://tc39.es/ecma402/#datetimeformat-objects
struct DateTimeFormat::Impl {
  std::u16string locale;
  std::u16string localeMatcher;
  std::u16string ca;
  std::u16string nu;
  std::u16string hc;
  std::u16string localeData;
};

DateTimeFormat::DateTimeFormat() : impl_(std::make_unique<Impl>()) {}
DateTimeFormat::~DateTimeFormat() {}

// Implementation of
// https://tc39.es/ecma402/#sec-intl.datetimeformat.supportedlocalesof
vm::CallResult<std::vector<std::u16string>> DateTimeFormat::supportedLocalesOf(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  // 1. Let availableLocales be %DateTimeFormat%.[[AvailableLocales]].
  NSArray<NSString *> *nsAvailableLocales = [NSLocale availableLocaleIdentifiers];
  
  // 2. Let requestedLocales be ? CanonicalizeLocaleList(locales).
  vm::CallResult<std::vector<std::u16string>> requestedLocales = getCanonicalLocales(runtime, locales);
  std::vector<std::u16string> availableLocales = nsStringArrayToU16StringArray(nsAvailableLocales);
  
  // 3. Return ? (availableLocales, requestedLocales, options).
  return supportedLocales(availableLocales, requestedLocales.getValue(), options);
}

// Implementation of 
// https://tc39.es/ecma402/#sec-todatetimeoptions
vm::CallResult<Options> toDateTimeOptions(const Options &options, std::u16string required, std::u16string defaults) {
  // 1. If options is undefined, let options be null; otherwise let options be ? ToObject(options).
  // 2. Let options be OrdinaryObjectCreate(options).
  // 3. Let needDefaults be true.
  bool needDefaults = true;
  // 4. If required is "date" or "any", then
  if (required == u"date" || required == u"any") {
    // a. For each property name prop of « "weekday", "year", "month", "day" », do
    for (std::u16string prop : {u"weekday", u"year", u"month", u"day"}) {
      // i. Let value be ? Get(options, prop).
        if (options.find(prop) != options.end()) {
        // ii. If value is not undefined, let needDefaults be false.
        needDefaults = false;
      }
    }
  }
  // 5. If required is "time" or "any", then
  if (required == u"time" || required == u"any") {
      // a. For each property name prop of « "dayPeriod", "hour", "minute", "second", "fractionalSecondDigits" », do
    for (std::u16string prop : {u"hour", u"minute", u"second"}) {
      // i. Let value be ? Get(options, prop).
      if (options.find(prop) != options.end()) {
        // ii. If value is not undefined, let needDefaults be false.
        needDefaults = false;
      }
    }
  }
  // 6. Let dateStyle be ? Get(options, "dateStyle").
  auto dateStyle = options.find(u"dateStyle");
  // 7. Let timeStyle be ? Get(options, "timeStyle").
  auto timeStyle = options.find(u"timeStyle");
  // 8. If dateStyle is not undefined or timeStyle is not undefined, let needDefaults be false.
  if (dateStyle != options.end() || timeStyle != options.end()) {
    needDefaults = false;
  }
  // 9. If required is "date" and timeStyle is not undefined, then
  if (required == u"date" && timeStyle != options.end()) {
    // a. Throw a TypeError exception.
    return vm::ExecutionStatus::EXCEPTION;
  }
  // 10. If required is "time" and dateStyle is not undefined, then
  if (required == u"time" && dateStyle != options.end()) {
    // a. Throw a TypeError exception.
    return vm::ExecutionStatus::EXCEPTION;
  }
  // 11. If needDefaults is true and defaults is either "date" or "all", then
  if (needDefaults && (defaults == u"date" || defaults == u"all")) {
    // a. For each property name prop of « "year", "month", "day" », do
    for (std::u16string prop : {u"year", u"month", u"day"}) {
      // TODO: implement createDataPropertyOrThrow
      // i. Perform ? CreateDataPropertyOrThrow(options, prop, "numeric").
    }
  }
  // 12. If needDefaults is true and defaults is either "time" or "all", then
  if (needDefaults && (defaults == u"time" || defaults == u"all")) {
    // a. For each property name prop of « "hour", "minute", "second" », do
    for (std::u16string prop : {u"hour", u"minute", u"second"}) {
      // i. Perform ? CreateDataPropertyOrThrow(options, prop, "numeric").
    }
  }
  // 13. return options
  return options;
}

// Implementation of
// https://tc39.es/ecma402/#sec-initializedatetimeformat
vm::ExecutionStatus DateTimeFormat::initialize(
    vm::Runtime *runtime,
    const std::vector<std::u16string> &locales,
    const Options &options) noexcept {
  // 1. Let requestedLocales be ? CanonicalizeLocaleList(locales).
  vm::CallResult<std::vector<std::u16string>> requestedLocales =
      getCanonicalLocales(runtime, locales);
  if (LLVM_UNLIKELY(requestedLocales == vm::ExecutionStatus::EXCEPTION)) {
    return vm::ExecutionStatus::EXCEPTION;
  }
  // 2. Let options be ? ToDateTimeOptions(options, "any", "date").
  auto o = toDateTimeOptions(options, u"any", u"date");
  // 3. Let opt be a new Record.
  Impl opt;
  // 4. Let matcher be ? GetOption(options, "localeMatcher", "string", «
  //   "lookup", "best fit" », "best fit").
  std::vector<std::u16string> values = {u"lookup", u"best fit"};
  Option matcherFallback = new Option(u"best fit");
  auto matcher = getOption(options, u"localeMatcher", u"string", values, matcherFallback);
  // 5. Set opt.[[localeMatcher]] to matcher.
  opt.localeMatcher = matcher;

  // 6. Let calendar be ? GetOption(options, "calendar", "string",
  //    undefined, undefined).
  std::vector<std::u16string> emptyVector;
  Option undefinedFallback = new Option(false); // TODO: Pass undefined.
  auto calendar = getOption(options, u"calendar", u"string", emptyVector, undefinedFallback);
  // 7. If calendar is not undefined, then
  //    a. If calendar does not match the Unicode Locale Identifier type
  //       nonterminal, throw a RangeError exception.
  // 8. Set opt.[[ca]] to calendar.
  if (calendar->size() != 0) {
      opt.ca = calendar;
  }
        
  // 9. Let numberingSystem be ? GetOption(options, "numberingSystem",
  //    "string", undefined, undefined).
  auto numberingSystem = getOption(options, u"numberingSystem", u"string", emptyVector, undefinedFallback);
  // 10. If numberingSystem is not undefined, then
  //     a. If numberingSystem does not match the Unicode Locale Identifier
  //        type nonterminal, throw a RangeError exception.
  // 11. Set opt.[[nu]] to numberingSystem.
  if (numberingSystem->size() != 0) {
      opt.nu = numberingSystem;
  }
        
  // 12. Let hour12 be ? GetOption(options, "hour12", "boolean",
  //     undefined, undefined).
  auto hour12 = getOption(options, u"hour12", u"boolean", emptyVector, undefinedFallback);
  // 13. Let hourCycle be ? GetOption(options, "hourCycle", "string", «
  //     "h11", "h12", "h23", "h24" », undefined).
  std::vector<std::u16string> hourCycleVector = {u"h11", u"h12", u"h23", u"h24"};
  auto hourCycle = getOption(options, u"hourCycle", u"string", hourCycleVector, undefinedFallback);
  // 14. If hour12 is not undefined, then
  //     a. Let hourCycle be null.
  if (hour12->size() != 0) {
      hourCycle = NULL;
  }
  // 15. Set opt.[[hc]] to hourCycle.
  opt.hc = hourCycle;
        
//  16. Let localeData be %DateTimeFormat%.[[LocaleData]].
  NSArray<NSString *> *nslocaleData = [NSLocale availableLocaleIdentifiers];
//  TODO: resolveLocale? https://tc39.es/ecma402/#sec-resolvelocale
    std::u16string r;
//  17. Let r be ResolveLocale(%DateTimeFormat%.[[AvailableLocales]], requestedLocales, opt, %DateTimeFormat%.[[RelevantExtensionKeys]], localeData).
//  18. Set dateTimeFormat.[[Locale]] to r.[[locale]].
//  19. Let calendar be r.[[ca]].
//  20. Set dateTimeFormat.[[Calendar]] to calendar.
//  21. Set dateTimeFormat.[[HourCycle]] to r.[[hc]].
//  22. Set dateTimeFormat.[[NumberingSystem]] to r.[[nu]].
//  23. Let dataLocale be r.[[dataLocale]].
  return vm::ExecutionStatus::RETURNED;
}

Options DateTimeFormat::resolvedOptions() noexcept {
  Options options;
  options.emplace(u"locale", Option(impl_->locale));
  options.emplace(u"numeric", Option(false));
  // Implementation of
  // https://tc39.es/ecma402/#sec-todatetimeoptions
  //        2. Let options be ? ToDateTimeOptions(options, "any", "date").
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
