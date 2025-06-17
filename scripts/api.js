const numId = args[0]

const apiResponse = await Functions.makeHttpRequest({
    url: "https://laboratories.onrender.com/api/v1/laboratories/${numId}/status"
})

if (apiResponse.error) {
    console.error(apiResponse.error) // delete?
    throw Error("Request failed")
}

const { data } = apiResponse;

if (data.status === "ACTIVE") {
    return Functions.encodeUint256(1);
} else {
    return Functions.encodeUint256(0);
}