# robertboscacci.com

Personal portfolio site built with [Hugo](https://gohugo.io/) and the [Congo](https://github.com/jpanther/congo) theme. Production deploys to GitHub Pages from `main`.

## Local development

```bash
git submodule update --init --recursive
hugo server --disableFastRender
```

For a production-equivalent build:

```bash
hugo --gc --minify --cleanDestinationDir --baseURL "https://robertboscacci.com/"
```

The GitHub Actions workflow currently pins Hugo `0.161.1`.
