const BigNumber = require("bignumber.js");

expect.extend({
  numEquals(actual, expected) {
    return {
      pass: actual.toString() == expected.toString(),
      message: () => `expected ${JSON.stringify(actual)} (${actual.toString()}) == ${JSON.stringify(expected)} (${expected.toString()})`
    }
  }
});

expect.extend({
  toRevert(actual, msg='revert') {
    return {
      pass: !!actual['message'] && actual.message === `VM Exception while processing transaction: ${msg}`,
      message: () => `expected revert, got: ${JSON.stringify(actual)}`
    }
  }
});

expect.extend({
  toAlmostEqual(actual, expected, precision) {
    const actualBig = new BigNumber(actual.toString()).toPrecision(precision);
    const expectedBig = new BigNumber(expected.toString()).toPrecision(precision);
    return {pass: actualBig === expectedBig,
        message: () => `expected ${expectedBig}, got: ${actualBig}`
    }
  }
});