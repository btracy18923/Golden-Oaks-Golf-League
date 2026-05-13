# Running the Website Locally

Use this to test changes before deploying to Netlify.

## Start the Server

Open a terminal and run:

```
cd C:\Users\ME\StudioProjects\Golden-Oaks-Golf-League\netlify_website
cmd /c npx http-server -p 8000
```

Then open **http://localhost:8000** in your browser.

## Notes

- Connects to **live Firebase data** — changes you make (announcements, play dates, email blasts) are real
- Use this to test `index.html` changes before pushing to Netlify
- Stop the server with **Ctrl+C** in the terminal

## Why not just open index.html directly?

Opening the file directly (`file://`) causes CORS errors with Firebase. The local server avoids this.
