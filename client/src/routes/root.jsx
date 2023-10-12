import { useLoaderData, Outlet } from "react-router-dom";
import { getSessionsCount } from "../sessions";
import { getUserInfo } from "../user";

export async function loader() {
  const sessionsCount = await getSessionsCount();
  const userInfo = await getUserInfo();
  return { userInfo, sessionsCount };
}

export default function Root() {
  const { userInfo, sessionsCount } = useLoaderData();

  return (
    <>
      <div id="header">
        <h1>Airlift 2023 Session Finder</h1>
        <div id="user-info">
          { userInfo ?
            <span>Welcome {userInfo.userDetails}! [<a href="/.auth/logout">Logout</a>] </span>
            :
            <a href="/.auth/login/aad">Login with Microsoft Entra ID</a>
          }
        </div>
        <p>
          Use OpenAI to search for interesting sessions. Write the topic you're interested in, and (up to) the top ten most interesting and related session will be returned.         
          The search is done using <a href="https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#embeddings-models">text embeddings</a> and then using <a href="https://en.wikipedia.org/wiki/Cosine_similarity" target="_blank">cosine similarity</a> to find the most similar sessions.
        </p>
        <p>There are {sessionsCount} sessions indexed so far.</p>
      </div>
      <div>
      { userInfo ?
        <Outlet /> : <div id="loginAlert">Login with a @microsoft account required to access this app, thanks.</div>
      }
      </div>
    </>
  );
}