var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/boolean.js
var require_boolean = __commonJS({
  "node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/boolean.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.boolean = void 0;
    var boolean = /* @__PURE__ */ __name(function(value) {
      switch (Object.prototype.toString.call(value)) {
        case "[object String]":
          return ["true", "t", "yes", "y", "on", "1"].includes(value.trim().toLowerCase());
        case "[object Number]":
          return value.valueOf() === 1;
        case "[object Boolean]":
          return value.valueOf();
        default:
          return false;
      }
    }, "boolean");
    exports2.boolean = boolean;
  }
});

// node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/tokenize.js
var require_tokenize = __commonJS({
  "node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/tokenize.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.tokenize = void 0;
    var TokenRule = /(?:%(?<flag>([+0-]|-\+))?(?<width>\d+)?(?<position>\d+\$)?(?<precision>\.\d+)?(?<conversion>[%BCESb-iosux]))|(\\%)/g;
    var tokenize = /* @__PURE__ */ __name((subject) => {
      let matchResult;
      const tokens = [];
      let argumentIndex = 0;
      let lastIndex = 0;
      let lastToken = null;
      while ((matchResult = TokenRule.exec(subject)) !== null) {
        if (matchResult.index > lastIndex) {
          lastToken = {
            literal: subject.slice(lastIndex, matchResult.index),
            type: "literal"
          };
          tokens.push(lastToken);
        }
        const match = matchResult[0];
        lastIndex = matchResult.index + match.length;
        if (match === "\\%" || match === "%%") {
          if (lastToken && lastToken.type === "literal") {
            lastToken.literal += "%";
          } else {
            lastToken = {
              literal: "%",
              type: "literal"
            };
            tokens.push(lastToken);
          }
        } else if (matchResult.groups) {
          lastToken = {
            conversion: matchResult.groups.conversion,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any -- intentional per @gajus
            flag: matchResult.groups.flag || null,
            placeholder: match,
            position: matchResult.groups.position ? Number.parseInt(matchResult.groups.position, 10) - 1 : argumentIndex++,
            precision: matchResult.groups.precision ? Number.parseInt(matchResult.groups.precision.slice(1), 10) : null,
            type: "placeholder",
            width: matchResult.groups.width ? Number.parseInt(matchResult.groups.width, 10) : null
          };
          tokens.push(lastToken);
        }
      }
      if (lastIndex <= subject.length - 1) {
        if (lastToken && lastToken.type === "literal") {
          lastToken.literal += subject.slice(lastIndex);
        } else {
          tokens.push({
            literal: subject.slice(lastIndex),
            type: "literal"
          });
        }
      }
      return tokens;
    }, "tokenize");
    exports2.tokenize = tokenize;
  }
});

// node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/createPrintf.js
var require_createPrintf = __commonJS({
  "node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/createPrintf.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.createPrintf = void 0;
    var boolean_1 = require_boolean();
    var tokenize_1 = require_tokenize();
    var formatDefaultUnboundExpression = /* @__PURE__ */ __name((_subject, token) => {
      return token.placeholder;
    }, "formatDefaultUnboundExpression");
    var createPrintf = /* @__PURE__ */ __name((configuration) => {
      var _a;
      const padValue = /* @__PURE__ */ __name((value, width, flag) => {
        if (flag === "-") {
          return value.padEnd(width, " ");
        } else if (flag === "-+") {
          return ((Number(value) >= 0 ? "+" : "") + value).padEnd(width, " ");
        } else if (flag === "+") {
          return ((Number(value) >= 0 ? "+" : "") + value).padStart(width, " ");
        } else if (flag === "0") {
          return value.padStart(width, "0");
        } else {
          return value.padStart(width, " ");
        }
      }, "padValue");
      const formatUnboundExpression = (_a = configuration === null || configuration === void 0 ? void 0 : configuration.formatUnboundExpression) !== null && _a !== void 0 ? _a : formatDefaultUnboundExpression;
      const cache2 = {};
      return (subject, ...boundValues) => {
        let tokens = cache2[subject];
        if (!tokens) {
          tokens = cache2[subject] = (0, tokenize_1.tokenize)(subject);
        }
        let result = "";
        for (const token of tokens) {
          if (token.type === "literal") {
            result += token.literal;
          } else {
            let boundValue = boundValues[token.position];
            if (boundValue === void 0) {
              result += formatUnboundExpression(subject, token, boundValues);
            } else if (token.conversion === "b") {
              result += (0, boolean_1.boolean)(boundValue) ? "true" : "false";
            } else if (token.conversion === "B") {
              result += (0, boolean_1.boolean)(boundValue) ? "TRUE" : "FALSE";
            } else if (token.conversion === "c") {
              result += boundValue;
            } else if (token.conversion === "C") {
              result += String(boundValue).toUpperCase();
            } else if (token.conversion === "i" || token.conversion === "d") {
              boundValue = String(Math.trunc(boundValue));
              if (token.width !== null) {
                boundValue = padValue(boundValue, token.width, token.flag);
              }
              result += boundValue;
            } else if (token.conversion === "e") {
              result += Number(boundValue).toExponential();
            } else if (token.conversion === "E") {
              result += Number(boundValue).toExponential().toUpperCase();
            } else if (token.conversion === "f") {
              if (token.precision !== null) {
                boundValue = Number(boundValue).toFixed(token.precision);
              }
              if (token.width !== null) {
                boundValue = padValue(String(boundValue), token.width, token.flag);
              }
              result += boundValue;
            } else if (token.conversion === "o") {
              result += (Number.parseInt(String(boundValue), 10) >>> 0).toString(8);
            } else if (token.conversion === "s") {
              if (token.width !== null) {
                boundValue = padValue(String(boundValue), token.width, token.flag);
              }
              result += boundValue;
            } else if (token.conversion === "S") {
              if (token.width !== null) {
                boundValue = padValue(String(boundValue), token.width, token.flag);
              }
              result += String(boundValue).toUpperCase();
            } else if (token.conversion === "u") {
              result += Number.parseInt(String(boundValue), 10) >>> 0;
            } else if (token.conversion === "x") {
              boundValue = (Number.parseInt(String(boundValue), 10) >>> 0).toString(16);
              if (token.width !== null) {
                boundValue = padValue(String(boundValue), token.width, token.flag);
              }
              result += boundValue;
            } else {
              throw new Error("Unknown format specifier.");
            }
          }
        }
        return result;
      };
    }, "createPrintf");
    exports2.createPrintf = createPrintf;
  }
});

// node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/printf.js
var require_printf = __commonJS({
  "node_modules/.pnpm/fast-printf@1.6.10/node_modules/fast-printf/dist/src/printf.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.printf = exports2.createPrintf = void 0;
    var createPrintf_1 = require_createPrintf();
    Object.defineProperty(exports2, "createPrintf", { enumerable: true, get: /* @__PURE__ */ __name(function() {
      return createPrintf_1.createPrintf;
    }, "get") });
    exports2.printf = (0, createPrintf_1.createPrintf)();
  }
});

// src/common/resource.ts
var IsBrowser = typeof window === "undefined" ? 0 : typeof window.GetParentResourceName !== "undefined" ? 1 : 2;
var ResourceContext = IsBrowser ? "web" : IsDuplicityVersion() ? "server" : "client";
var ResourceName = IsBrowser ? IsBrowser === 1 ? window.GetParentResourceName() : "nui-frame-app" : GetCurrentResourceName();

// src/common/utils.ts
function LoadFile(path) {
  return LoadResourceFile(ResourceName, path);
}
__name(LoadFile, "LoadFile");
function LoadJsonFile(path) {
  if (!IsBrowser) return JSON.parse(LoadFile(path));
  const resp = fetch(`/${path}`, {
    method: "post",
    headers: {
      "Content-Type": "application/json; charset=UTF-8"
    }
  });
  return resp.then((response) => response.json());
}
__name(LoadJsonFile, "LoadJsonFile");

// src/common/config.ts
var config = LoadJsonFile("static/config.json");
var config_default = config;

// node_modules/.pnpm/@overextended+ox_lib@3.29.0/node_modules/@overextended/ox_lib/shared/resource/cache/index.js
var cacheEvents = {};
var cache = new Proxy({
  resource: GetCurrentResourceName(),
  game: GetGameName()
}, {
  get(target, key) {
    const result = key ? target[key] : target;
    if (result !== void 0)
      return result;
    cacheEvents[key] = [];
    AddEventHandler(`ox_lib:cache:${key}`, (value) => {
      const oldValue = target[key];
      const events = cacheEvents[key];
      events.forEach((cb) => cb(value, oldValue));
      target[key] = value;
    });
    target[key] = exports.ox_lib.cache(key) || false;
    return target[key];
  }
});

// node_modules/.pnpm/@overextended+ox_lib@3.29.0/node_modules/@overextended/ox_lib/shared/resource/locale/index.js
var import_fast_printf = __toESM(require_printf());
var dict = {};
function flattenDict(source2, target, prefix) {
  for (const key in source2) {
    const fullKey = prefix ? `${prefix}.${key}` : key;
    const value = source2[key];
    if (typeof value === "object")
      flattenDict(value, target, fullKey);
    else
      target[fullKey] = String(value);
  }
  return target;
}
__name(flattenDict, "flattenDict");
var locale = /* @__PURE__ */ __name((str, ...args) => {
  const lstr = dict[str];
  if (!lstr)
    return str;
  if (lstr) {
    if (typeof lstr !== "string")
      return lstr;
    if (args.length > 0) {
      return (0, import_fast_printf.printf)(lstr, ...args);
    }
    return lstr;
  }
  return str;
}, "locale");
function loadLocale(key) {
  const data = LoadResourceFile(cache.resource, `locales/${key}.json`);
  if (!data)
    console.warn(`could not load 'locales/${key}.json'`);
  return JSON.parse(data) || {};
}
__name(loadLocale, "loadLocale");
var initLocale = /* @__PURE__ */ __name((key) => {
  const lang = key || exports.ox_lib.getLocaleKey();
  let locales = loadLocale("en");
  if (lang !== "en")
    Object.assign(locales, loadLocale(lang));
  const flattened = flattenDict(locales, {});
  for (let [k, v] of Object.entries(flattened)) {
    if (typeof v === "string") {
      const regExp = new RegExp(/\$\{([^}]+)\}/g);
      const matches = v.match(regExp);
      if (matches) {
        for (const match of matches) {
          if (!match)
            break;
          const variable = match.substring(2, match.length - 1);
          let locale2 = flattened[variable];
          if (locale2) {
            v = v.replace(match, locale2);
          }
        }
      }
    }
    dict[k] = v;
  }
}, "initLocale");
initLocale();

// src/common/locale.ts
function Locale(str, ...args) {
  return locale(str, ...args);
}
__name(Locale, "Locale");
var locale_default = Locale;

// src/common/index.ts
function Greetings() {
  const greetings = locale_default("hello");
  console.log(`started dist/${ResourceContext}.js`);
  console.log(greetings);
}
__name(Greetings, "Greetings");

// node_modules/.pnpm/@overextended+ox_lib@3.29.0/node_modules/@overextended/ox_lib/server/resource/acl/index.js
var addAce = /* @__PURE__ */ __name((principal, ace, allow) => exports.ox_lib.addAce(principal, ace, allow), "addAce");

// node_modules/.pnpm/@overextended+ox_lib@3.29.0/node_modules/@overextended/ox_lib/server/resource/addCommand/index.js
var registeredCommmands = [];
var shouldSendCommands = false;
setTimeout(() => {
  shouldSendCommands = true;
  emitNet("chat:addSuggestions", -1, registeredCommmands);
}, 1e3);
on("playerJoining", () => {
  emitNet("chat:addSuggestions", source, registeredCommmands);
});
function parseArguments(source2, args, raw, params) {
  if (!params)
    return args;
  const result = params.every((param, index) => {
    const arg = args[index];
    let value;
    switch (param.paramType) {
      case "number":
        value = +arg;
        break;
      case "string":
        value = !Number(arg) ? arg : false;
        break;
      case "playerId":
        value = arg === "me" ? source2 : +arg;
        if (!value || !DoesPlayerExist(value.toString()))
          value = false;
        break;
      case "longString":
        value = raw.substring(raw.indexOf(arg));
        break;
      default:
        value = arg;
        break;
    }
    if (value === void 0 && (!param.optional || param.optional && arg)) {
      return Citizen.trace(`^1command '${raw.split(" ")[0] || raw}' received an invalid ${param.paramType} for argument ${index + 1} (${param.name}), received '${arg}'^0`);
    }
    args[param.name] = value;
    delete args[index];
    return true;
  });
  return result ? args : void 0;
}
__name(parseArguments, "parseArguments");
function addCommand(commandName, cb, properties) {
  const restricted = properties?.restricted;
  const params = properties?.params;
  if (params) {
    params.forEach((param) => {
      if (param.paramType)
        param.help = param.help ? `${param.help} (type: ${param.paramType})` : `(type: ${param.paramType})`;
    });
  }
  const commands = typeof commandName !== "object" ? [commandName] : commandName;
  const numCommands = commands.length;
  const commandHandler = /* @__PURE__ */ __name((source2, args, raw) => {
    const parsed = parseArguments(source2, args, raw, params);
    if (!parsed)
      return;
    cb(source2, parsed, raw).catch((e) => Citizen.trace(`^1command '${raw.split(" ")[0] || raw}' failed to execute!^0
${e.message}`));
  }, "commandHandler");
  commands.forEach((commandName2, index) => {
    RegisterCommand(commandName2, commandHandler, restricted ? true : false);
    if (restricted) {
      const ace = `command.${commandName2}`;
      const restrictedType = typeof restricted;
      if (restrictedType === "string" && !IsPrincipalAceAllowed(restricted, ace)) {
        addAce(restricted, ace, true);
      } else if (restrictedType === "object") {
        const _restricted = restricted;
        _restricted.forEach((principal) => {
          if (!IsPrincipalAceAllowed(principal, ace))
            addAce(principal, ace, true);
        });
      }
    }
    if (properties) {
      properties.name = `/${commandName2}`;
      delete properties.restricted;
      registeredCommmands.push(properties);
      if (index !== numCommands && numCommands !== 1)
        properties = { ...properties };
      if (shouldSendCommands)
        emitNet("chat:addSuggestions", -1, properties);
    }
  });
}
__name(addCommand, "addCommand");

// src/server/index.ts
Greetings();
if (config_default.EnableNuiCommand) {
  addCommand("openNui", async (playerId) => {
    if (!playerId) return;
    emitNet(`${cache.resource}:openNui`, playerId);
  });
}
