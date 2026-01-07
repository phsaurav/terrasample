import { check, group } from "k6";
import http from "k6/http";

export const options = {
    iterations: 1,
    vus: 1,
};

export function cdnCacheTest() {
    group("CDN Cache Verification", function () {
        const cdnUrls = [
            "https://cdn.golfindev.tech",
            "https://gamecdn.golfindev.tech",
            "https://gamecdn.golfin-stage.com",
            "https://cdn.golfinsrv.com",
            "https://gamecdn.golfinsrv.com",
        ];

        console.log(
            `🚀 Starting CDN cache verification for ${cdnUrls.length} CDNs`
        );

        cdnUrls.forEach((cdn, index) => {
            console.log(
                `📍 Testing CDN ${index + 1}/${cdnUrls.length}: ${cdn}`
            );

            const res1 = http.get(`${cdn}/banner-golfin-v1.png`);

            const firstStatusCheck = check(res1, {
                "First request status is 200": (r) => r.status === 200,
            });

            const res2 = http.get(`${cdn}/banner-golfin-v1.png`);

            const secondStatusCheck = check(res2, {
                "Second request status is 200": (r) => r.status === 200,
            });

            // Check cache headers
            const cacheControl = res2.headers["X-Cache"];
            const cacheHeaderCheck = check(cacheControl, {
                "Cache control header exists": (h) =>
                    h === "Hit from cloudfront",
            });

            const allChecksPassed =
                firstStatusCheck && secondStatusCheck && cacheHeaderCheck;

            if (!allChecksPassed) {
                console.error(`  ❌ FAILED: ${cdn}`);

                if (!firstStatusCheck) {
                    console.error(
                        `First request failed - Status: ${res1.status}`
                    );
                }
                if (!secondStatusCheck) {
                    console.error(
                        `Second request failed - Status: ${res2.status}`
                    );
                }
                if (!cacheHeaderCheck) {
                    console.error(`    Cache control header missing`);
                }
            } else {
                console.log(`  ✅ Cache HIT: ${cdn}`);
            }
        });

        console.log(`\n🏁 Completed CDN cache verification for all ${cdnUrls.length}
DNs`);
    });
}

export default function () {
    cdnCacheTest();
}
