'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "80f5db98cfd860329d1c0c7b7d71c1f2",
"version.json": "19a79c97090c29d22b606fe8d23fa8ac",
"index.html": "1946864b362898f2b437e56f6c098fcd",
"/": "1946864b362898f2b437e56f6c098fcd",
"main.dart.js": "3d5828eb1a78e6ab87d9369cf22c4459",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "73ad2d6ee6ae68d678c93e6620727b19",
"assets/NOTICES": "b918c36234b022732b2cb06c9113d256",
"assets/FontManifest.json": "74ed93e6893ed76ad4c5a6b9cfa8c463",
"assets/AssetManifest.bin.json": "400380915bafd00bbef7f831c3ebdaa0",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "eb247f4417b3c105bc6964a2370586ec",
"assets/fonts/MaterialIcons-Regular.otf": "0799ad806aac679b7c3e41df51c40bfb",
"assets/assets/forma/forma8.png": "1394d58f1fb870003d22647a7155d430",
"assets/assets/forma/ball.png": "0486a57d1b3f56aa1c8996315d677454",
"assets/assets/forma/ball1.png": "2565280ce2a25f34b4e6d4cd4324bd8a",
"assets/assets/forma/ball3.png": "e4fad179dbb7bb57268094f66baf38b1",
"assets/assets/forma/ball2.png": "dcb9a58fea7251316ad6d19d42b44659",
"assets/assets/forma/ball4.png": "5162b341d3973a9091e3c25a0b3288b1",
"assets/assets/forma/forma0.png": "7167bd9ec105ee895c8e1365f7e4f871",
"assets/assets/forma/forma1.png": "c3d61d60ab69deed17a75a43e6023cc8",
"assets/assets/forma/forma3.png": "7902a3c5c6634782ecf29db69a70d366",
"assets/assets/forma/forma2.png": "452e90445c60b2ce85d8e32839fd145b",
"assets/assets/forma/forma6.png": "ff10dee7f7e81dc7a074bfa9d04563d6",
"assets/assets/forma/forma7.png": "58804c7a3f285d6617ef55d36cd0d812",
"assets/assets/forma/forma5.png": "aac4cd0b70855c152e9c342fe8d19523",
"assets/assets/forma/ChatGPT%2520Image%25204%2520Ag%25CC%2586u%25202forma8026%252021_52_23%2520Arka%2520Plan%25C4%25B1%2520Silindi.png": "6eff0c8f20d5dc87bc346998a1ddd206",
"assets/assets/forma/forma4.png": "d6e2dadded11d11884cdf6796b59e7c8",
"assets/assets/dashboard/dash1.png": "e7e3fb1099a2651d864ef2ced0fdea88",
"assets/assets/dashboard/player1.png": "b2afac027bdbc827c90b4d27a3ef4ede",
"assets/assets/dashboard/male-football-player-field-rain.jpg": "dc27b7bef5ededd95f53c4cfa4ba0e55",
"assets/assets/dashboard/es.jpg": "4c33bb179d6b653368e147bb033184b7",
"assets/assets/dashboard/top2.jpg": "bf3d1f2ffa706acdcd8c002e96145dad",
"assets/assets/dashboard/top.png": "fb7b29e3f3b59285ba834fb0429f8e50",
"assets/assets/dashboard/top1.jpg": "3adf01ab96e3b67bc63aeaeaa1084065",
"assets/assets/dashboard/v4%2520Arka%2520Plan%25C4%25B1%2520Silindi.png": "bb2506d422550b5d80d4c8f476a618f7",
"assets/assets/dashboard/fm.jpg": "52b1ef5d72dfadc7299d28d50e5dc158",
"assets/assets/dashboard/ds.jpg": "6e6b1627e588816bbb4deb07ecfe6a7f",
"assets/assets/dashboard/v3.png": "19da08e9856fa2c72e9ed1b2949e204e",
"assets/assets/dashboard/v2.png": "a3c67ddf971ba4f143bf2ddecea7a8d3",
"assets/assets/dashboard/player.png": "8f4c0dbbda0c67f6a3d8eb8864c8cde1",
"assets/assets/fonts/Inter-Variable.ttf": "bff0f6e3b9e2259a28313168a907054f",
"assets/assets/fonts/Anton-Regular.ttf": "da0af4e9427ac8ddcac1a4eb0fb06f69",
"assets/assets/data/player_profile.json": "211e90bbc1d39cfb4f668bb74626038c",
"assets/assets/saha/Saha2.png": "1e45f7c75b8997197d8df62c860a9a10",
"assets/assets/saha/saha3.png": "9c1d83e0c954fa4b80540b6d19f29ae6",
"assets/assets/saha/saha4.png": "21a477eaaeaa7c246b404c5020de40ae",
"assets/assets/saha/saha5.png": "51e6faed4b0cf771b7c255cc3d20e561",
"assets/assets/saha/saha.jpg": "f7d78a310552233dfd4fadc528fd4865",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
