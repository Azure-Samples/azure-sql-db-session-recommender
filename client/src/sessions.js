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
  var sessions = []; 
  var errorInfo = null;
  if (data.value.length > 0) {
    if (data.value[0].error_code) {
        errorInfo = {
          errorSource: data.value[0].error_source,
          errorCode: data.value[0].error_code,
          errorMessage: data.value[0].error_message
        };
    } else {
      sessions = data.value;
    }
  }
 
  return {sessions:sessions, errorInfo:errorInfo};
}

export async function getSessionsCount() {
  const response = await fetch("/data-api/rest/GetSessionsCountAggregate");
  if (!response.ok) return 'n/a';
  const data = await response.json();
  const totalCount = (data) ? data.value[0].TotalSessionsCount : "n/a";
  return totalCount;
}
