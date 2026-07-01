#!/bin/bash

BASE_MEDIA="/mnt/hdd2/media"

menu_picker() {
  local prompt_msg="$1"
  shift
  printf "%s\n" "$@" | fzf --prompt="$prompt_msg" --height=40% --reverse --border
}

select_audio_device() {
  clear
  echo "========================================"
  echo " 🔊 [ ALSA HARDWARE AUDIO TARGETS ]     "
  echo "========================================"
  echo "1) 🔊 Desktop Speakers (ALC897 Analog Line-Out)"
  echo "2) 📺 Sharp TV (NVIDIA HDMI 1 Output Node)"
  echo "3) 🎧 Razer Headset (Kraken Ultimate USB Card)"
  echo "========================================"
  read -p "Select Sound Output Terminal (1-3): " AUDIO_CHOICE

  case "$AUDIO_CHOICE" in
    1) echo "alsa/plughw:CARD=Generic_1,DEV=0" ;;
    2) echo "alsa/plughw:CARD=NVidia,DEV=7" ;;
    3) echo "alsa/plughw:CARD=Ultimate,DEV=0" ;;
    *) echo "alsa/plughw:CARD=Generic_1,DEV=0" ;; # Default safe fallback to speakers
  esac
}

main_menu() {
  while true; do
    clear
    echo "========================================"
    echo " 🎬 [ JAKES • NVIDIA • 4K • MASTER ]   "
    echo "========================================"
    echo "1) 🎬 Movies"
    echo "2) 🎵 Music"
    echo "3) 📺 TV Shows"
    echo "4) 🚪 Exit"
    echo "========================================"
    read -p "Select Media Sector (1-4): " SECTOR_CHOICE

    case "$SECTOR_CHOICE" in
      1) handle_flat_sector "Movies" ; return ;;
      2) handle_music_sector ; return ;;
      3) handle_tv_sector ; return ;;
      4|*) clear; exit 0 ;;
    esac
  done
}

handle_flat_sector() {
  local sector_name="$1"
  local target_dir="$BASE_MEDIA/$sector_name"
  cd "$target_dir" 2>/dev/null || { echo "Directory not found!"; sleep 1; main_menu; return; }

  clear
  echo "Scanning $sector_name Library..."
  echo "================================================================"

  local target_file
  target_file=$(find . -mindepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | sed 's|^\./||' | fzf --prompt="💿 Select $sector_name Asset: ")

  if [ ! -z "$target_file" ]; then
    launch_mpv_video "$target_dir/$target_file"
  else
    main_menu
  fi
}

handle_music_sector() {
  local music_dir="$BASE_MEDIA/Music"
  cd "$music_dir" 2>/dev/null || { echo "Music directory not found!"; sleep 1; main_menu; return; }

  local chosen_album=""
  local chosen_track=""

  while true; do
    clear
    local albums=()
    while IFS= read -r d; do albums+=("$d"); done < <(find . -maxdepth 1 -type d -not -path . | sed 's|^\./||' | sort)
    
    if [ ${#albums[@]} -eq 0 ]; then
      chosen_album=""
      break
    fi

    chosen_album=$(menu_picker "🎵 Select Music Album / Folder: " "◀ GO BACK TO MAIN MENU" "${albums[@]}")

    if [ -z "$chosen_album" ] || [ "$chosen_album" = "◀ GO BACK TO MAIN MENU" ]; then
      main_menu; return
    fi
    break
  done

  while true; do
    clear
    if [ -z "$chosen_album" ]; then
      cd "$music_dir" 2>/dev/null || { main_menu; return; }
      local search_path="."
    else
      cd "$music_dir/$chosen_album" 2>/dev/null || { handle_music_sector; return; }
      local search_path="."
    fi

    local tracks=()
    while IFS= read -r f; do tracks+=("$f"); done < <(find "$search_path" -maxdepth 1 -type f \( -iname "*.flac" -o -iname "*.mp3" -o -iname "*.m4a" \) | sed 's|^\./||' | sort)

    if [ ${#tracks[@]} -eq 0 ]; then
      echo "No high-fidelity audio tracks found inside this folder."
      sleep 2; handle_music_sector; return
    fi

    chosen_track=$(menu_picker "💿 Select Audio Track: " "◀ GO BACK TO ALBUMS" "${tracks[@]}")

    if [ -z "$chosen_track" ] || [ "$chosen_track" = "◀ GO BACK TO ALBUMS" ]; then
      handle_music_sector; return
    fi
    break
  done

  if [ -z "$chosen_album" ] ; then
    launch_mpv_audio "$music_dir/$chosen_track"
  else
    launch_mpv_audio "$music_dir/$chosen_album/$chosen_track"
  fi
}

handle_tv_sector() {
  local tv_dir="$BASE_MEDIA/TV Shows"
  cd "$tv_dir" 2>/dev/null || { echo "TV Shows directory not found!"; sleep 1; main_menu; return; }

  local chosen_show=""
  local chosen_season=""
  local chosen_episode=""

  while true; do
    clear
    local shows=()
    while IFS= read -r d; do shows+=("$d"); done < <(find . -maxdepth 1 -type d -not -path . | sed 's|^\./||' | sort)
    
    if [ ${#shows[@]} -eq 0 ]; then
      echo "No Show folders found inside $tv_dir."
      sleep 2; main_menu; return
    fi

    chosen_show=$(menu_picker "📺 Select TV Show: " "◀ GO BACK TO MAIN MENU" "${shows[@]}")

    if [ -z "$chosen_show" ] || [ "$chosen_show" = "◀ GO BACK TO MAIN MENU" ]; then
      main_menu; return
    fi
    break
  done

  while true; do
    clear
    cd "$tv_dir/$chosen_show" 2>/dev/null || { main_menu; return; }
    
    local seasons=()
    while IFS= read -r d; do seasons+=("$d"); done < <(find . -maxdepth 1 -type d -not -path . | sed 's|^\./||' | sort)

    if [ ${#seasons[@]} -eq 0 ]; then
      chosen_season=""
      break
    fi

    chosen_season=$(menu_picker "📁 Select Season: " "◀ GO BACK TO SHOWS" "${seasons[@]}")

    if [ -z "$chosen_season" ] || [ "$chosen_season" = "◀ GO BACK TO SHOWS" ]; then
      handle_tv_sector; return
    fi
    break
  done

  while true; do
    clear
    if [ -z "$chosen_season" ]; then
      cd "$tv_dir/$chosen_show" 2>/dev/null || { main_menu; return; }
      local search_path="."
    else
      cd "$tv_dir/$chosen_show/$chosen_season" 2>/dev/null || { handle_tv_sector; return; }
      local search_path="."
    fi

    local episodes=()
    while IFS= read -r f; do episodes+=("$f"); done < <(find "$search_path" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | sed 's|^\./||' | sort)

    if [ ${#episodes[@]} -eq 0 ]; then
      echo "No video files found in this section."
      sleep 2; handle_tv_sector; return
    fi

    chosen_episode=$(menu_picker "💿 Select Episode: " "◀ GO BACK TO SEASONS" "${episodes[@]}")

    if [ -z "$chosen_episode" ] || [ "$chosen_episode" = "◀ GO BACK TO SEASONS" ]; then
      cd "$tv_dir"
      handle_tv_sector
      return
    fi
    break
  done

  if [ -z "$chosen_season" ]; then
    launch_mpv_video "$tv_dir/$chosen_show/$chosen_episode"
  else
    launch_mpv_video "$tv_dir/$chosen_show/$chosen_season/$chosen_episode"
  fi
}

launch_mpv_video() {
  local file_path="$1"
  local target_audio=$(select_audio_device)
  killall -9 mpv 2>/dev/null; pkill -9 -f mpv 2>/dev/null
  /usr/bin/mpv \
    --audio-device="$target_audio" \
    --hwdec=nvdec \
    --vo=gpu \
    --gpu-context=wayland \
    --scale=lanczos \
    --cscale=lanczos \
    --video-sync=display-resample \
    --demuxer-max-bytes=2GiB \
    --demuxer-max-back-bytes=500MiB \
    --autofit=720x405 \
    --ontop \
    --title="JAKES_MEDIA_CONTAINER" \
    "$file_path" >/dev/null 2>&1 &
}

launch_mpv_audio() {
  local file_path="$1"
  local target_audio=$(select_audio_device)
  killall -9 mpv 2>/dev/null; pkill -9 -f mpv 2>/dev/null
  /usr/bin/mpv \
    --audio-device="$target_audio" \
    --vo=gpu \
    --gpu-context=wayland \
    --force-window=yes \
    --audio-display=attachment \
    --autofit=450x450 \
    --ontop \
    --title="JAKES_AUDIO_CONTAINER" \
    "$file_path" >/dev/null 2>&1 &
}

main_menu
