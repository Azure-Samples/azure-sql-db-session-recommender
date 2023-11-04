import React, { Suspense } from "react";
import { useLoaderData, Outlet, Await, defer } from "react-router-dom";
import { getSessionsCount } from "../sessions";
import { getUserInfo } from "../user";
import ls from 'localstorage-slim';

export async function loader() {
  const sessionsCount = getSessionsCount();
  const userInfo = await getUserInfo();
  return defer({ userInfo, sessionsCount });
}

function showSessionCount(sessionsCount) {  
  var sc = sessionsCount;
  if (sc == undefined) {
    sc = ls.get("sessionsCount");
  } else {
    ls.set("sessionsCount", sc, { ttl: 60 * 24 * 7 });
  }
  if (sc == undefined) {
    return (<p className="font-subtitle-2">Loading session count...</p>);
  }  
  return (
    <p className="font-subtitle-2">There are {sc} sessions indexed so far.</p>
  );
}


export default function Root() {
  const { userInfo, sessionsCount } = useLoaderData();

  return (
    <>
      <div id="header">
        <h1 className="font-title-2">Cool Conference Session Finder</h1>
        <p className="font-subtitle-2 user-info">
          { userInfo ?
            <span>Welcome {userInfo.userDetails}! [<a href="/logout">Logout</a>] </span>
            :
            <a href="/login">Login with Microsoft Entra ID</a>
          }
        </p>
        <p className="font-subtitle-2">
          Use OpenAI to search for interesting sessions. Write the topic you're interested in, and (up to) the top ten most interesting and related session will be returned.         
          The search is done using <a href="https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#embeddings-models">text embeddings</a> and then using <a href="https://en.wikipedia.org/wiki/Cosine_similarity" target="_blank">cosine similarity</a> to find the most similar sessions.
        </p>
        <p className="font-subtitle-2">
          Source code and and related articles is <a href="https://github.com/Azure-Samples/azure-sql-db-session-recommender">available on GitHub.</a>
        </p>
        <React.Suspense fallback={showSessionCount()}>
          <Await resolve={sessionsCount} errorElement={(<p className="font-subtitle-2">Unable to load session count 😥...</p>)}>
          {(sessionsCount) => showSessionCount(sessionsCount)}
          </Await>        
        </React.Suspense>
      </div>
      <div>      
        <Outlet /> 
      </div>
    </>
  );
}