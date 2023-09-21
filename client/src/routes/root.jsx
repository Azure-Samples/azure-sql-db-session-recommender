import { useEffect } from "react";
import { Form, useLoaderData, useNavigation, } from "react-router-dom";
import { getSessions } from "../sessions";

export async function loader({ request }) {
    const url = new URL(request.url);
    const q = url.searchParams.get("q");
    //console.log(q);
    const sessions = q == '' ? [] : await getSessions(q);
    return { sessions, q };
}

export default function Root() {
    const { sessions, q } = useLoaderData();
    const navigation = useNavigation();

    const searching =
      navigation.location &&
      new URLSearchParams(navigation.location.search).has(
        "q"
      );

    useEffect(() => {
      document.getElementById("q").value = q;
    }, [q]);

    return (
      <>
          <div id="searchbox">
            <h1>Airlift 2023 Session Finder</h1>        
            <div>
              <Form id="search-form" role="search">
                <input
                  id="q"
                  className={searching ? "loading" : ""}
                  aria-label="Search contacts"
                  placeholder="Search"
                  type="search"
                  name="q"
                  defaultValue={q}
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
              <i>{q != "" ? "No session found" : "Use OpenAI to search for a session that will be interesting for you"}</i>
            </p>
          )}
          </div>          
      </>
    );
  }