# GEMINI.md

## Project Overview

This project is a custom desktop shell for the Niri Wayland compositor. It is built using QML and provides a modern, customizable user interface. The shell includes features like a top bar, notifications, on-screen displays (OSD), and desktop decorations.

The shell is designed to be highly configurable through QML files, allowing users to customize the appearance and behavior of the desktop environment.

## Key Files

-   `shell.qml`: The main entry point of the application. It initializes all the different UI components.
-   `config/Settings.qml`: Contains all the hardcoded values for the shell, such as animation durations, sizes, and margins.
-   `config/Theme.qml`: Defines the semantic color and styling for the shell. It uses a color palette from `common/Colors.json`.
-   `common/Colors.json`: A JSON file that defines the color palette used by the theme.
-   `core/Niri.qml`: A singleton that subscribes to Niri's event stream and provides the current state of the compositor to the rest of the application. It reads the status from `/tmp/niri_status.json`.
-   `scripts/niri_status.py`: A Python script that listens to Niri's event stream and writes the current status to `/tmp/niri_status.json`.
-   `features/bar/Bar.qml`: The main top bar component, which displays workspaces, the current window title, and system indicators.
-   `features/notifications/NotificationManager.qml`: Manages notification popups, including stacking, positioning, and lifecycle.
-   `core/NotificationStore.qml`: Manages persistent storage of notifications in a JSON file.

## Architecture

The shell is structured into several directories:

-   `components`: Contains reusable UI components, such as cards, buttons, and indicators.
-   `config`: Contains the main configuration files for the shell, `Settings.qml` and `Theme.qml`.
-   `core`: Contains the core logic of the shell, such as the Niri integration and notification service.
-   `features`: Contains the main UI features of the shell, such as the bar, notifications, and OSD.
-   `scripts`: Contains helper scripts, such as the `niri_status.py` script.

The application follows a modular architecture, with each feature being implemented as a separate QML component. The `core` components provide data and services to the `features` and `components`.

## Configuration

The shell can be configured by modifying the following files:

-   `config/Settings.qml`: To change the dimensions, animations, and other hardcoded values.
-   `config/Theme.qml`: To change the colors and styles of the shell.
-   `common/Colors.json`: To change the color palette.

## Development

To run the shell, you need to have Niri installed and running. The `niri_status.py` script must also be running in the background.

To start the shell, run the following command:

```bash
niri
```

The shell will automatically be loaded by Niri.
