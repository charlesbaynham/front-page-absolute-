# Front Page Absolute

A single-page website built with Jekyll and Bootstrap, configured for deployment with GitHub Pages.

## Features

- Single-page responsive website
- Bootstrap 5 default template
- Nix flake for reproducible builds
- GitHub Pages deployment via GitHub Actions
- Live reload development server

## Development

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled

### Commands

```bash
# Start development server with live reload on http://localhost:4000
nix run

# Build the static site to ./result
nix build

# Enter development shell (optional)
nix develop
```

The site will be available at `http://localhost:4000` when running the development server.

## Deployment

The site runs on the home lab as a [cattle container](https://github.com/charlesbaynham/nix-proxmox-cattle): every commit to `main` builds a Proxmox LXC template and publishes it as a release asset, the hypervisor polls for it, and the container is replaced. It is declared as `frontpage` in `homelab-infra`'s `services.yaml` and published at the apex, `https://houseabsolute.co.uk/`, through the border router.

There is no state, no secret and nothing to seed — the site is a store path baked into the image, so changing a word here is a new container.

```bash
nix build .#proxmoxLxcTemplate   # what CI publishes
```

## Project Structure

```
.
├── _config.yml              # Jekyll configuration
├── _layouts/
│   └── default.html         # Bootstrap-based layout
├── index.md                 # Main page content
├── flake.nix                # Nix flake configuration
└── .github/
    ├── workflows/
    │   └── jekyll-gh-pages.yml  # GitHub Pages deployment
    └── copilot-instructions.md   # Copilot guidelines
```

## License

MIT