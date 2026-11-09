# GitHub Pages Setup for Privacy Policy

This guide will help you host the Medify privacy policy on GitHub Pages to get a public URL for your Play Store listing.

---

## Quick Setup Steps

### Option 1: Using GitHub Web Interface (Recommended - Easiest)

1. **Go to Your Repository Settings**

   - Navigate to: https://github.com/Sumit-Piston/medify
   - Click on **Settings** tab
   - Scroll down to **Pages** section in the left sidebar

2. **Enable GitHub Pages**

   - Under "Build and deployment":
     - Source: Select **Deploy from a branch**
     - Branch: Select **main**
     - Folder: Select **/ (root)**
   - Click **Save**

3. **Wait for Deployment**

   - GitHub will build and deploy your site
   - This usually takes 1-2 minutes
   - You'll see a message: "Your site is live at `https://sumit-piston.github.io/medify/`"

4. **Access Your Privacy Policy**

   - Your privacy policy will be available at:
   - **`https://sumit-piston.github.io/medify/PRIVACY_POLICY`**
   - Or with extension: **`https://sumit-piston.github.io/medify/PRIVACY_POLICY.html`**

5. **Verify It's Live**
   - Click the provided link to test
   - If you get a 404, wait another minute and refresh

---

### Option 2: Create a Custom Privacy Policy Page (Better Formatting)

If you want a nicer-looking privacy policy page:

1. **Create an `index.html` file in a `docs` folder:**

```bash
mkdir -p docs
```

2. **Create `docs/privacy-policy.html`:**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Medify - Privacy Policy</title>
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
          Oxygen, Ubuntu, Cantarell, sans-serif;
        line-height: 1.6;
        color: #333;
        max-width: 800px;
        margin: 0 auto;
        padding: 20px;
        background-color: #f5f5f5;
      }
      .container {
        background-color: white;
        padding: 40px;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      }
      h1 {
        color: #2196f3;
        border-bottom: 3px solid #2196f3;
        padding-bottom: 10px;
      }
      h2 {
        color: #1976d2;
        margin-top: 30px;
      }
      h3 {
        color: #0d47a1;
      }
      .highlight {
        background-color: #e3f2fd;
        padding: 15px;
        border-left: 4px solid #2196f3;
        margin: 20px 0;
      }
      .important {
        background-color: #fff3e0;
        padding: 15px;
        border-left: 4px solid #ff9800;
        margin: 20px 0;
      }
      ul {
        list-style-type: none;
        padding-left: 0;
      }
      ul li:before {
        content: "✓ ";
        color: #4caf50;
        font-weight: bold;
        margin-right: 5px;
      }
      .no-collect li:before {
        content: "❌ ";
      }
      a {
        color: #2196f3;
        text-decoration: none;
      }
      a:hover {
        text-decoration: underline;
      }
      .footer {
        margin-top: 40px;
        padding-top: 20px;
        border-top: 1px solid #ddd;
        text-align: center;
        color: #666;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <!-- Copy the content from PRIVACY_POLICY.md here, formatted as HTML -->
      <!-- Or use a Markdown-to-HTML converter -->

      <h1>Privacy Policy for Medify</h1>
      <p><strong>Last Updated: October 16, 2025</strong></p>

      <div class="highlight">
        <strong>Important:</strong> Medify operates on a privacy-first
        principle. All your data is stored locally on your device. We do not
        collect, transmit, or store any of your personal information on external
        servers.
      </div>

      <!-- Continue with rest of the content... -->
      <!-- You can use a tool like https://markdowntohtml.com/ to convert PRIVACY_POLICY.md -->

      <div class="footer">
        <p>&copy; 2025 Medify. All rights reserved.</p>
        <p>
          <a href="https://github.com/Sumit-Piston/medify">GitHub Repository</a>
        </p>
      </div>
    </div>
  </body>
</html>
```

3. **Enable GitHub Pages with docs folder:**

   - Go to Settings → Pages
   - Branch: **main**
   - Folder: Select **/docs**
   - Click Save

4. **Your URL will be:**
   - **`https://sumit-piston.github.io/medify/privacy-policy.html`**

---

### Option 3: Use Markdown Directly (Simplest)

GitHub Pages can render Markdown automatically:

1. **Enable GitHub Pages (main branch, root)**

2. **Access your privacy policy at:**

   - **`https://sumit-piston.github.io/medify/PRIVACY_POLICY`**

3. **Add this to your Play Store listing:**
   ```
   Privacy Policy: https://sumit-piston.github.io/medify/PRIVACY_POLICY
   ```

---

## Recommended Approach

**For Play Store submission, I recommend Option 1 (simplest):**

1. Enable GitHub Pages from Settings
2. Use the URL: `https://sumit-piston.github.io/medify/PRIVACY_POLICY`
3. This works immediately with your existing file

---

## Testing Your Privacy Policy URL

After enabling GitHub Pages:

1. Wait 2-3 minutes for deployment
2. Open the URL in your browser
3. Verify the content displays correctly
4. Share this URL in your Play Store listing

---

## Updating the Privacy Policy

Whenever you need to update the privacy policy:

1. Edit `PRIVACY_POLICY.md` in your repository
2. Commit and push changes:
   ```bash
   git add PRIVACY_POLICY.md
   git commit -m "docs: Update privacy policy"
   git push origin main
   ```
3. GitHub Pages will automatically redeploy (1-2 minutes)
4. Changes will be live at the same URL

---

## Alternative: Use a Custom Domain (Optional)

If you want a custom domain like `medify.yourdomain.com`:

1. Buy a domain (from Namecheap, GoDaddy, etc.)
2. Add a `CNAME` file to your repository:
   ```
   medify.yourdomain.com
   ```
3. Configure DNS in your domain registrar:
   - Add CNAME record pointing to `sumit-piston.github.io`
4. In GitHub Settings → Pages → Custom domain:
   - Enter: `medify.yourdomain.com`
   - Check "Enforce HTTPS"

---

## Quick Commands Reference

```bash
# Check your current repository
git remote -v

# Create docs folder for Option 2
mkdir -p docs

# Push privacy policy updates
git add PRIVACY_POLICY.md
git commit -m "docs: Update privacy policy"
git push origin main

# Check GitHub Pages status
# Visit: https://github.com/Sumit-Piston/medify/settings/pages
```

---

## Play Store Requirement

For Google Play Store, you need:

- ✅ A publicly accessible URL
- ✅ HTTPS enabled (GitHub Pages provides this)
- ✅ Content that matches your app's data practices

Your privacy policy URL will be:
**`https://sumit-piston.github.io/medify/PRIVACY_POLICY`**

Add this URL to:

- Play Store listing → Store presence → Privacy policy
- App settings page (already done in `settings_page.dart`)

---

## Troubleshooting

### "404 - Page Not Found"

- Wait 2-3 minutes after enabling GitHub Pages
- Check that GitHub Pages is enabled in Settings → Pages
- Verify the file name is exactly `PRIVACY_POLICY.md` (case-sensitive)
- Try adding `.html` extension to the URL

### "Site is taking too long to deploy"

- Check Actions tab for build status
- Ensure your repository is public or you have GitHub Pages enabled for private repos

### "Privacy policy not rendering correctly"

- GitHub renders Markdown by default
- For custom styling, use Option 2 with HTML
- Ensure file encoding is UTF-8

---

## Next Steps

1. ✅ Enable GitHub Pages (Option 1 recommended)
2. ✅ Wait for deployment (2-3 minutes)
3. ✅ Test the URL: `https://sumit-piston.github.io/medify/PRIVACY_POLICY`
4. ✅ Add URL to Play Store listing
5. ✅ Add URL to app's Settings → About section (if not already done)

---

**Support:** If you encounter issues, check the [GitHub Pages documentation](https://docs.github.com/en/pages)
