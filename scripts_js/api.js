if (!args || !args[0]) {
    throw new Error("The laboratory identifier (numId) is required in arguments.");
}

const apiResponse = await Functions.makeHttpRequest({
    url: `https://laboratories.onrender.com/api/v1/laboratories/${args[0]}/status`,
});

return Functions.encodeUint256(
    apiResponse.error ? 0 : apiResponse.data === "ACTIVE" ? 1 : 0
);