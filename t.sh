#!/bin/bash

# Fungsi untuk menampilkan logo & informasi awal
print_welcome_message() {
    echo -e "\033[1;37m"
    echo " _  _ _   _ ____ ____ _    ____ _ ____ ___  ____ ____ ___ "
    echo "|\\ |  \\_/  |__| |__/ |    |__| | |__/ |  \\ |__/ |  | |__]"
    echo "| \\|   |   |  | |  \\ |    |  | | |  \\ |__/ |  \\ |__| |    "
    echo -e "\033[1;32m"
    echo "Nyari Airdrop Auto install Drosera CLI Node (GitHub Codespaces Version)"
    echo -e "\033[1;33m"
    echo "Telegram: https://t.me/nyariairdrop"
    echo -e "\033[0m"
}

# Tampilkan pesan selamat datang
print_welcome_message

# === Cek System Requirements ===
# GitHub Codespaces biasanya memiliki spesifikasi yang memadai,
# tetapi kita tetap memeriksa untuk memastikan
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -lt 2 ]; then
  echo "⚠️ Warning: CPU Cores kurang dari 2. Performa mungkin terbatas."
else
  echo "✅ CPU Cores: $CPU_CORES"
fi

RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
if [ "$RAM_TOTAL" -lt 3900 ]; then
  echo "⚠️ Warning: RAM kurang dari 4 GB. Performa mungkin terbatas."
else
  echo "✅ RAM: $RAM_TOTAL MB"
fi

DISK_FREE=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$DISK_FREE" -lt 20 ]; then
  echo "⚠️ Warning: Disk space kurang dari 20 GB. Performa mungkin terbatas."
else
  echo "✅ Disk space: $DISK_FREE GB"
fi

echo "🔄 Melanjutkan instalasi di GitHub Codespaces..."

# Ambil IP dengan cara yang kompatibel dengan Codespaces
# Untuk Codespaces, sebaiknya gunakan port forwarding daripada IP langsung
echo "🔄 GitHub Codespaces menggunakan port forwarding, tidak perlu IP publik tetap"
# Kita akan menggunakan localhost untuk konfigurasi internal
CODESPACE_NAME=$(echo $GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN | cut -d '.' -f1)
echo "✅ Codespace name: $CODESPACE_NAME"

# Minta input user
read -p "Masukkan Github Email: " GIT_EMAIL
read -p "Masukkan Github Username: " GIT_USERNAME
read -p "Masukkan EVM Private Key (0x...): " PRIVATE_KEY
read -p "Masukkan EVM Public Address (0x...): " PUBLIC_ADDRESS

# Update & install dependencies
# Paket sudah terinstal di Codespaces, jadi kita meminimalkan update
echo "🔄 Update dan install dependencies..."
sudo apt-get update
sudo apt install curl ufw jq make gcc nano automake autoconf tmux htop pkg-config libssl-dev libleveldb-dev -y

# Docker sudah terinstal di Codespaces, jadi kita bisa melewati bagian ini
echo "✅ Docker sudah terinstal di GitHub Codespaces"
docker --version

# Install Drosera CLI dengan path yang benar
echo "🔄 Menginstall Drosera CLI..."
curl -L https://app.drosera.io/install | bash
source ~/.bashrc
export PATH=$PATH:$HOME/.drosera/bin
if ! command -v drosera &> /dev/null; then
    echo "⚠️ Drosera CLI tidak terdeteksi di PATH"
    if [ -f "$HOME/.drosera/bin/drosera" ]; then
        echo "✅ Ditemukan di $HOME/.drosera/bin/drosera, menambahkan ke PATH"
        export PATH=$PATH:$HOME/.drosera/bin
        echo 'export PATH=$PATH:$HOME/.drosera/bin' >> ~/.bashrc
    else
        echo "❌ Drosera CLI tidak ditemukan. Mencoba menginstal ulang..."
        curl -L https://app.drosera.io/install | bash
        source ~/.bashrc
        export PATH=$PATH:$HOME/.drosera/bin
    fi
fi
droseraup

# Verifikasi instalasi Drosera
if ! command -v drosera &> /dev/null; then
    echo "❌ Instalasi Drosera CLI gagal. Coba manual dengan:"
    echo "curl -L https://app.drosera.io/install | bash"
    echo "source ~/.bashrc"
    echo "export PATH=\$PATH:\$HOME/.drosera/bin"
    echo "droseraup"
    exit 1
fi

# Install Foundry
echo "🔄 Menginstall Foundry..."
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup

# Install Bun
echo "🔄 Menginstall Bun..."
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
export PATH=$PATH:$HOME/.bun/bin
echo 'export PATH=$PATH:$HOME/.bun/bin' >> ~/.bashrc

# Create trap directory
echo "🔄 Membuat directory trap..."
mkdir -p ~/my-drosera-trap && cd ~/my-drosera-trap

# Set git config
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USERNAME"

# Initialize Trap project
echo "🔄 Menginisialisasi Trap project..."
forge init -t drosera-network/trap-foundry-template

# Install bun dependencies & build
echo "🔄 Menginstall dependencies dan build trap..."
$HOME/.bun/bin/bun install
forge build

# Verify drosera is available
echo "🔄 Verifikasi Drosera CLI..."
DROSERA_COMMAND=""
if command -v drosera &> /dev/null; then
    DROSERA_COMMAND="drosera"
elif [ -f "$HOME/.drosera/bin/drosera" ]; then
    DROSERA_COMMAND="$HOME/.drosera/bin/drosera"
else
    echo "❌ Drosera command tidak ditemukan. Coba install ulang."
    exit 1
fi

# Deploy Trap dengan interaksi manual
echo "🔄 Melakukan deploy Trap..."
echo "⚠️ PENTING: Ketika diminta, ketik 'ofc' dan tekan Enter"
echo "💡 Menjalankan: DROSERA_PRIVATE_KEY=$PRIVATE_KEY $DROSERA_COMMAND apply"
DROSERA_PRIVATE_KEY=$PRIVATE_KEY $DROSERA_COMMAND apply

# Verifikasi trap di dashboard
echo -e "\n\n🔄 Langkah 1: Verifikasi trap di dashboard"
echo "🔗 Kunjungi https://app.drosera.io/ di browser Anda dan hubungkan wallet Anda"
echo "📋 Cek trap Anda di 'Traps Owned' atau cari dengan alamat trap"
echo "⏳ Tekan ENTER setelah memverifikasi trap Anda muncul di dashboard..."
read -p "" verify_trap_deployed

# Run dryrun untuk fetch blocks
echo "🔄 Menjalankan dryrun untuk fetch blocks..."
$DROSERA_COMMAND dryrun

# Bloom Boost trap
echo -e "\n\n🔄 Langkah 2: Melakukan Bloom Boost pada trap"
echo "🔗 Kunjungi trap Anda di dashboard"
echo "💰 Klik pada 'Send Bloom Boost' dan deposit beberapa Holesky ETH"
echo "⏳ Tekan ENTER setelah melakukan Bloom Boost untuk melanjutkan..."
read -p "" verify_bloom_boost

# Konfigurasi whitelist untuk operator
echo -e "\n\n🔄 Langkah 3: Mengkonfigurasi whitelist operator..."
echo -e "\n\nprivate_trap = true\nwhitelist = [\"$PUBLIC_ADDRESS\"]" >> drosera.toml
echo "✅ Whitelist operator ditambahkan ke drosera.toml"

# Apply konfigurasi whitelist
echo "🔄 Menerapkan konfigurasi whitelist..."
DROSERA_PRIVATE_KEY=$PRIVATE_KEY $DROSERA_COMMAND apply

# Sistem pengulangan untuk memastikan trap menjadi private
MAX_ATTEMPTS=3
attempts=0
trap_private=false

while [ $attempts -lt $MAX_ATTEMPTS ] && [ "$trap_private" = false ]; do
  ((attempts++))
  
  echo -e "\n\n🔄 Langkah 4: Memverifikasi status PRIVATE (Percobaan $attempts dari $MAX_ATTEMPTS)"
  echo "⏳ Menunggu konfigurasi privasi trap diterapkan..."
  echo "⚠️ PENTING: Silakan cek trap Anda di dashboard untuk memverifikasi statusnya"
  echo "🔗 Kunjungi https://app.drosera.io/"
  echo "📋 Trap Anda harus menunjukkan status 'PRIVATE'"
  
  read -p "Apakah trap Anda sudah berstatus PRIVATE? (y/n): " trap_status
  
  if [[ "$trap_status" == "y" || "$trap_status" == "Y" ]]; then
    trap_private=true
    echo "✅ Trap berhasil diatur menjadi PRIVATE!"
  else
    echo "❌ Trap belum berhasil diatur menjadi PRIVATE. Mencoba mengatur ulang..."
    echo "🔄 Memeriksa konfigurasi drosera.toml..."
    
    # Pastikan whitelist konfigurasi sudah benar
    if ! grep -q "private_trap = true" drosera.toml || ! grep -q "whitelist = \[\"$PUBLIC_ADDRESS\"\]" drosera.toml; then
      echo "🔄 Memperbaiki konfigurasi whitelist di drosera.toml..."
      # Hapus konfigurasi yang mungkin sudah ada tapi salah format
      sed -i '/private_trap/d' drosera.toml
      sed -i '/whitelist/d' drosera.toml
      # Tambahkan konfigurasi dengan format yang benar
      echo -e "\n# Whitelist configuration\nprivate_trap = true\nwhitelist = [\"$PUBLIC_ADDRESS\"]" >> drosera.toml
    fi
    
    echo "🔄 Mencoba menerapkan konfigurasi whitelist lagi..."
    DROSERA_PRIVATE_KEY=$PRIVATE_KEY $DROSERA_COMMAND apply
    
    echo "⏳ Tunggu sekitar 30 detik untuk memastikan transaksi dikonfirmasi..."
    sleep 30
  fi
done

if [ "$trap_private" = false ]; then
  echo "❌ Tidak berhasil mengatur trap menjadi PRIVATE setelah $MAX_ATTEMPTS kali percobaan."
  echo "⚠️ Anda dapat mencoba mengatur secara manual dengan langkah-langkah berikut:"
  echo "1. Edit file drosera.toml"
  echo "2. Pastikan ada baris 'private_trap = true'"
  echo "3. Pastikan ada baris 'whitelist = [\"$PUBLIC_ADDRESS\"]'"
  echo "4. Jalankan: DROSERA_PRIVATE_KEY=$PRIVATE_KEY $DROSERA_COMMAND apply"
  echo "5. Periksa dashboard untuk memverifikasi status"
  
  read -p "Apakah Anda ingin melanjutkan proses instalasi meskipun trap belum private? (y/n): " continue_anyway
  if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
    echo "🛑 Instalasi dihentikan. Silakan coba lagi nanti."
    exit 1
  fi
  echo "⚠️ Melanjutkan instalasi meskipun trap belum private. Opt-in mungkin akan gagal."
else
  echo "🎉 Konfigurasi trap private berhasil! Melanjutkan proses instalasi..."
fi

# Kembali ke home directory
cd ~

# Install Operator CLI
echo -e "\n\n🔄 Langkah 5: Menginstall Operator CLI..."
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin

# Test Operator CLI
echo "🔄 Testing Operator CLI..."
drosera-operator --version

# Register operator
echo -e "\n\n🔄 Langkah 6: Mendaftarkan operator..."
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $PRIVATE_KEY

# Detect ports in Codespaces
P2P_PORT=31313
SERVER_PORT=31314

# Configure port forwarding in Codespaces
echo -e "\n\n🔄 Langkah 7: Mengkonfigurasi port forwarding di Codespaces..."
# Untuk port forwarding di Codespaces, kita akan menggunakan GitHub CLI
# Pastikan pengguna memiliki port terbuka yang dapat diakses publik

echo "🔄 Membuka port $P2P_PORT untuk P2P traffic..."
gh codespace ports visibility $P2P_PORT:public -c $CODESPACE_NAME

echo "🔄 Membuka port $SERVER_PORT untuk Server traffic..."
gh codespace ports visibility $SERVER_PORT:public -c $CODESPACE_NAME

# Create service file yang akan dijalankan dengan tmux di Codespaces
echo -e "\n\n🔄 Langkah 8: Menyiapkan script untuk menjalankan node..."
cat > $HOME/run_drosera_node.sh <<EOF
#!/bin/bash
drosera-operator node --db-file-path $HOME/.drosera.db --network-p2p-port $P2P_PORT --server-port $SERVER_PORT \
  --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \
  --eth-backup-rpc-url https://1rpc.io/holesky \
  --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \
  --eth-private-key $PRIVATE_KEY \
  --listen-address 0.0.0.0 \
  --network-external-p2p-address localhost \
  --disable-dnr-confirmation true
EOF

chmod +x $HOME/run_drosera_node.sh

# Jalankan dengan tmux
echo -e "\n\n🔄 Langkah 9: Menjalankan node dalam tmux session..."
tmux new-session -d -s drosera "$HOME/run_drosera_node.sh"

echo "✅ Node dijalankan dalam tmux session. Untuk melihat log, jalankan: tmux attach -t drosera"

# Tampilkan informasi port forwarding
echo -e "\n\n🔄 Langkah 10: Informasi port forwarding di Codespaces"
echo "🔗 URL P2P: https://$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:$P2P_PORT"
echo "🔗 URL Server: https://$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:$SERVER_PORT"
echo "⚠️ PENTING: Catat URL ini untuk keperluan konfigurasi opt-in trap Anda"

echo -e "\n\n🔄 Langkah 11: Opt-in Trap"
echo "🔗 Kunjungi dashboard Drosera: https://app.drosera.io/"
echo "📋 Buka trap Anda dan klik tombol 'Opt-in' untuk menghubungkan operator dengan Trap"
echo "⚠️ PENTING: Jika tombol 'Opt-in' tidak muncul atau proses gagal, pastikan:"
echo "  1. Trap sudah berstatus PRIVATE"
echo "  2. Alamat wallet Anda ($PUBLIC_ADDRESS) sudah benar di whitelist"
echo "  3. Transaksi whitelist sudah dikonfirmasi di blockchain"
echo "  4. Port forwarding untuk P2P dan Server sudah dikonfigurasi dengan benar"

echo -e "\n\n🔄 Langkah 12: Verifikasi Node Liveness"
echo "🔗 Di dashboard, trap Anda akan mulai menampilkan blok hijau jika semuanya berjalan dengan baik"
echo "📋 Ini menandakan node Anda aktif dan terhubung dengan benar"
echo "💡 Untuk melihat log node, jalankan: tmux attach -t drosera"
echo "💡 Untuk keluar dari tmux tanpa mematikan node, tekan: Ctrl+B lalu D"

echo -e "\n\n⚠️ PENTING: Codespaces Sleep Warning ⚠️"
echo "GitHub Codespaces akan hibernate setelah tidak aktif selama periode tertentu."
echo "Ini akan menghentikan node Drosera Anda."
echo "Untuk menghindari ini, pastikan Anda menjaga Codespaces tetap aktif atau"
echo "mengkonfigurasi webhook keep-alive sesuai kebutuhan GitHub Codespaces."

echo -e "\n\n=== Instalasi selesai! ==="
echo "✅ Jika semua langkah telah dilakukan dengan benar, node Anda akan mulai berkontribusi ke jaringan Drosera"
echo "🎉 Terima kasih telah menggunakan script auto-install versi GitHub Codespaces dari Nyari Airdrop!"
