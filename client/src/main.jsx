import * as React from "react";
import * as ReactDOM from "react-dom/client";
import {
  createBrowserRouter,
  RouterProvider,
  useRouteLoaderData,
} from "react-router-dom";

import "./index.css";

import Root, { loader as rootLoader } from "./routes/root";
import SessionsList, { loader as sessionsListLoader } from "./routes/sessionsList";

const router = createBrowserRouter([
  {
    path: "/", 
    element: <Root />,
    loader: rootLoader,
    children: [{
      index: true,
      element: <SessionsList />,
      loader: sessionsListLoader,
    }]
  },
]);

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);