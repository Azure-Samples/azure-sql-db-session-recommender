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

  const response = await fetch("/data-api/rest/find", settings);
  if (!response.ok) {
    return { 
      sessions: [], 
      errorInfo: {
        errorSource: 'Server',
        errorCode: response.status,
        errorMessage: response.statusText
    }};
  };
  
  var sessions = []; 
  var errorInfo = null;
  const data = await response.json();

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
  const response = await fetch("/data-api/rest/sessions-count");
  if (!response.ok) return 'n/a';
  const data = await response.json();
  const totalCount = (data) ? data.value[0].total_sessions : "n/a";
  return totalCount;
}
