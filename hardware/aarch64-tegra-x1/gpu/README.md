# GPU — GM20B (Maxwell)

## Deux chemins, un seul praticable aujourd'hui

| Chemin | Pilote | Accélération | État |
|---|---|---|---|
| BSP NVIDIA | `nvgpu` (blob, noyau L4T) | complète (OpenGL ES, Vulkan via blobs) | dépend du noyau Switchroot |
| Mainline | `nouveau` + Mesa (NVK) | partielle, en cours | expérimental sur T210 |

OmarchySwitch 0.1.0 ne fournit **aucun** pilote GPU : il utilise celui du noyau
Switchroot, donc `nvgpu`. Le chemin `nouveau` est une piste pour une version
ultérieure et n'est pas testé ici.

## Ce qu'il faut pour que Hyprland s'affiche

1. un noyau avec `tegra_drm`/`nvgpu` et le firmware GPU du BSP ;
2. des bibliothèques EGL/GBM côté utilisateur, fournies par les paquets NVIDIA
   du BSP — **pas** par Mesa seul ;
3. un compositeur en mode DRM/KMS, ce que Hyprland fait nativement.

Sans les blobs BSP, Hyprland échoue au démarrage avec une erreur de contexte
EGL. Ce n'est pas un bug de configuration : c'est l'absence du pilote.

## Performances attendues (ordre de grandeur, non mesuré ici)

| Usage | Attente |
|---|---|
| Bureau 720p, terminal, navigateur léger | confortable |
| Waybar + animations Hyprland | à surveiller : les animations coûtent cher sur GM20B |
| Vidéo 1080p | accélération via VIC/NVDEC si firmware présent |
| Jeux 3D | hors périmètre de cette base |

Aucun chiffre n'est mesuré : ne pas les reprendre comme des benchmarks.

## Recommandations de configuration

- Désactiver ou réduire les animations Hyprland sur Switch.
- Éviter le scaling fractionnaire (voir `display/`).
- Préférer un terminal léger (`foot`) à un terminal GPU-lourd.

## Vérifications à faire sur console

```bash
# après démarrage (si systemd fonctionne un jour)
dmesg | grep -iE 'tegra|nvgpu|drm'
ls /dev/dri
glxinfo -B 2>/dev/null || eglinfo 2>/dev/null
```

Absence de `/dev/dri/card0` : le pilote DRM n'est pas chargé, inutile de
chercher plus loin côté compositeur.
