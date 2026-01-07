import { cdnCacheTest } from "./cdn-cache-test.js";
import { infraSmokeTests } from "./infra-smoke-test.js";

export default function () {
    infraSmokeTests();
    cdnCacheTest();
}
