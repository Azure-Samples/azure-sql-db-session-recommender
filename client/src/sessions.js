export async function getSessions(content) {
  const settings = {
    method: "post",
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      text: content
    })
  };

  const response = await fetch("/data-api/rest/FindRelatedSessions", settings);
  const data = await response.json();
  return data.value;
}

export async function getSessionsCount() {
  const response = await fetch("/data-api/rest/GetSessionsCountAggregate");
  const data = await response.json();
  return data.value[0].TotalSessionsCount;
}
