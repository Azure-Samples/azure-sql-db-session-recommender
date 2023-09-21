import { useEffect } from "react";
import { Form, useLoaderData, useNavigation, } from "react-router-dom";
import { getSessions, getSessionsCount } from "../sessions";
import { getUserInfo } from "../user";

export async function loader({ request }) {
    const url = new URL(request.url);
    const searchQuery = url.searchParams.get("q") ?? "";    
    //console.log(`q1: ${searchQuery}`); 
    const isSearch = (searchQuery == "" ) ? false : true;
    const sessions =  isSearch ? await getSessions(searchQuery) : [];  
    const sessionsCount = await getSessionsCount();
    const userInfo = await getUserInfo(request);
    return { userInfo, sessionsCount, sessions, searchQuery, isSearch };
}

export default function Root() {
    const { userInfo, sessionsCount, sessions, searchQuery, isSearch} = useLoaderData();
    const navigation = useNavigation();

    //console.log(`q2: ${searchQuery}`);

    const searching =
      navigation.location &&
      new URLSearchParams(navigation.location.search).has(
        "q"
      );

    useEffect(() => {
      document.getElementById("q").value = searchQuery;
    }, [searchQuery]);

    return (
      <>
          <div id="searchbox">
            <h1>Airlift 2023 Session Finder</h1>     
            <div id="user-info">
              { userInfo ? 
                <span>Welcome {userInfo.userDetails}!</span> 
                : 
                <a href="/.auth/login/aad">Login with Microsoft Entra ID</a>
              }
            </div>   
            <p>Use OpenAI to search for a session that will be interesting for you. Write the topic you're interested about, and a list of the most related session will be given to you. There are {sessionsCount} session indexed so far.</p>                        
            <div>
              <Form id="search-form" role="search">
                <input
                  id="q"
                  className={searching ? "loading" : ""}
                  aria-label="Search sessions"
                  placeholder="Search"
                  type="search"
                  name="q"
                  defaultValue={searchQuery}
                />        
                <div id="search-spinner" aria-hidden hidden={!searching} />
                <div className="sr-only" aria-live="polite"></div>       
                <button type="submit">Search</button>                             
              </Form>
            </div>              
          </div>
          <div id="sessions" className={navigation.state === "loading" ? "loading" : ""}>
          {sessions.length ? (
            <ul>
              {sessions.map((session) => (
                <li key={session.id}>
                    <h2>{ session.title } </h2>
                    <div>
                      { session.abstract }
                    </div>
                </li>
              ))}
            </ul>
          ) : (
            <p>
              <i>{isSearch ? "No session found" : "Use OpenAI to search for a session that will be interesting for you"}</i>
            </p>
          )}
          </div>          
      </>
    );
  }