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
        <h1 className="font-title-2">Cool Conference Session Finder</h1>
        <div id="user-info">
          { userInfo ?
            <span>Welcome {userInfo.userDetails}! [<a href="/logout">Logout</a>] </span>
            :
            <a href="/login">Login with Microsoft Entra ID</a>
          }
        </div>
        <p className="font-subtitle-2">
          Use OpenAI to search for interesting sessions. Write the topic you're interested in, and (up to) the top ten most interesting and related session will be returned.         
          The search is done using <a href="https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#embeddings-models">text embeddings</a> and then using <a href="https://en.wikipedia.org/wiki/Cosine_similarity" target="_blank">cosine similarity</a> to find the most similar sessions.
        </p>
        <p className="font-subtitle-2">There are {sessionsCount} sessions indexed so far.</p>
      </div>
      <div>      
        <Outlet /> 
      </div>
    </>
  );
}