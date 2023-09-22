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
  if (!response.ok) return '[]';
  const data = await response.json();
  return data.value;
}

export async function getSessionsCount() {
  const response = await fetch("/data-api/rest/GetSessionsCountAggregate");
  if (!response.ok) return 'n/a';
  const data = await response.json();
  const totalCount = (data) ? data.value[0].TotalSessionsCount : "n/a";
  return totalCount;
}
