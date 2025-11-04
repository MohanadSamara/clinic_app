// Forwarder for sqflite_common_ffi_web service worker
// Ensures the worker is available at /sqflite_sw.js as expected by the package
// Docs: https://github.com/tekartik/sqflite/tree/master/packages_web/sqflite_common_ffi_web#setup-binaries

// Use absolute path so it works regardless of base href
self.importScripts("/assets/packages/sqflite_common_ffi_web/assets/sqflite_sw.js");