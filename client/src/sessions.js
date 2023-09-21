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

  const response = await fetch("/data-api/rest/RelatedSessions", settings);
  const data = await response.json();
  return data.value;
}
