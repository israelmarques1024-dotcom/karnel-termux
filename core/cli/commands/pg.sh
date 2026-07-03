#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

# Variables de PostgreSQL
PG_DATA="$PREFIX/var/lib/postgresql"
PG_LOG="$OMNI_CACHE/postgresql.log"
PG_USER="postgres"

# Mostrar ayuda
pg_help() {
	echo
	box "Omni PostgreSQL Manager"
	echo
	log_info "Usage: omni pg <command> [options]"
	echo
	separator_section "Available Commands"
	echo
	printf "    ${D_CYAN}%-12s${NC} %s\n" "start" "Start PostgreSQL server"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "stop" "Stop PostgreSQL server"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "restart" "Restart PostgreSQL server"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "status" "Check PostgreSQL status"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "init" "Initialize PostgreSQL database"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "create" "Create a new database"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "drop" "Drop a database"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "backup" "Backup a database with compression & checksum"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "restore" "Restore a database from a compressed file"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "list-backups" "List available database backups"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "schedule" "Schedule automatic backups via cron"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "list" "List all databases"
	printf "    ${D_CYAN}%-12s${NC} %s\n" "shell" "Open psql shell"
	echo
	separator_section "Examples"
	echo
	printf "    ${D_CYAN}omni pg start${NC}              # Start PostgreSQL\n"
	printf "    ${D_CYAN}omni pg backup mydb${NC}        # Backup 'mydb'\n"
	printf "    ${D_CYAN}omni pg restore mydb${NC}       # Restore 'mydb'\n"
	printf "    ${D_CYAN}omni pg list-backups${NC}      # List backups table\n"
	printf "    ${D_CYAN}omni pg schedule${NC}          # Setup automated crontab backup\n"
	printf "    ${D_CYAN}omni pg shell${NC}              # Open psql shell\n"
	echo
}

# Verificar si PostgreSQL está instalado
check_pg_installed() {
	if ! command -v pg_ctl &>/dev/null; then
		log_error "PostgreSQL is not installed"
		log_info "Run: ${D_CYAN}omni install db${NC}"
		return 1
	fi
	return 0
}

# Verificar si está inicializado (solo informativo)
check_pg_initialized() {
	# Verificar múltiples rutas posibles
	local data_dirs=(
		"$PREFIX/var/lib/postgresql/data"
		"$PG_DATA/data"
		"$HOME/.termux/postgresql/data"
		"$PREFIX/var/lib/postgresql/data"
	)

	for dir in "${data_dirs[@]}"; do
		if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
			# Actualizar PG_DATA a la ruta correcta
			PG_DATA="$(dirname "$dir")"
			return 0
		fi
	done

	# También verificar si el servicio está corriendo
	if pg_ctl status &>/dev/null; then
		return 0
	fi

	return 1
}

# Inicializar PostgreSQL
pg_init() {
	separator
	box "Initializing PostgreSQL"
	separator
	echo

	check_pg_installed || return 1

	# Verificar si ya está inicializado
	if check_pg_initialized; then
		log_warn "PostgreSQL is already initialized"
		echo
		list_item "Data directory: $PG_DATA"
		list_item "Run: ${D_CYAN}omni pg start${NC}"
		echo
		return 0
	fi

	mkdir -p "$PG_DATA"

	log_info "Initializing PostgreSQL database..."
	echo

	# En Termux, initdb necesita ejecutarse como el usuario actual
	if loading "Initializing database" _pg_init_db; then
		log_success "PostgreSQL initialized successfully"
		echo
		list_item "Data directory: $PG_DATA"
		list_item "Default user: $PG_USER"
		echo
		log_info "Start PostgreSQL with: ${D_CYAN}omni pg start${NC}"
	else
		log_error "Failed to initialize PostgreSQL"
		log_warn "Check log: $PG_LOG"
		return 1
	fi

	echo
}

_pg_init_db() {
	initdb -D "$PG_DATA" &>"$PG_LOG" 2>&1
}

# Iniciar PostgreSQL
pg_start() {
	separator
	box "Starting PostgreSQL"
	separator
	echo

	check_pg_installed || return 1

	# Intentar detectar la ruta de datos antes de iniciar
	local found_dir=""
	local data_dirs=(
		"$PREFIX/var/lib/postgresql"
		"$PREFIX/var/lib/postgresql/data"
		"$PG_DATA"
		"$PG_DATA/data"
		"$HOME/.termux/postgresql"
		"$HOME/.termux/postgresql/data"
	)

	for dir in "${data_dirs[@]}"; do
		if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
			PG_DATA="$dir"
			found_dir="$dir"
			break
		fi
	done

	# Si no encontramos datos, intentar init primero
	if [[ -z "$found_dir" ]]; then
		log_warn "PostgreSQL not initialized yet"
		log_info "Initializing first..."
		mkdir -p "$PG_DATA"
		if ! loading "Initializing database" _pg_init_db; then
			log_error "Failed to initialize PostgreSQL"
			log_warn "Check log: $PG_LOG"
			return 1
		fi
	fi

	log_info "Starting PostgreSQL server..."

	if loading "Starting PostgreSQL" _pg_start_server; then
		log_success "PostgreSQL started successfully"
		echo
		list_item "Listening on: localhost:5432"
		list_item "User: $PG_USER"
		echo
	else
		log_error "Failed to start PostgreSQL"
		log_warn "Check log: $PG_LOG"
		return 1
	fi

	echo
}

_pg_start_server() {
	pg_ctl -D "$PG_DATA" -l "$PG_LOG" start 2>&1
	sleep 2
	# Verificar que efectivamente arrancó
	pg_ctl -D "$PG_DATA" status &>/dev/null
}

# Detener PostgreSQL
pg_stop() {
	separator
	box "Stopping PostgreSQL"
	separator
	echo

	check_pg_installed || return 1

	# Intentar detectar la ruta de datos
	local found_dir=""
	local data_dirs=(
		"$PREFIX/var/lib/postgresql"
		"$PREFIX/var/lib/postgresql/data"
		"$PG_DATA"
		"$PG_DATA/data"
		"$HOME/.termux/postgresql"
		"$HOME/.termux/postgresql/data"
	)

	for dir in "${data_dirs[@]}"; do
		if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
			PG_DATA="$dir"
			found_dir="$dir"
			break
		fi
	done

	log_info "Stopping PostgreSQL server..."

	if loading "Stopping PostgreSQL" _pg_stop_server; then
		log_success "PostgreSQL stopped successfully"
	else
		log_error "Failed to stop PostgreSQL"
		log_warn "PostgreSQL may not be running"
		return 1
	fi

	echo
}

_pg_stop_server() {
	pg_ctl -D "$PG_DATA" stop &>/dev/null
}

# Reiniciar PostgreSQL
pg_restart() {
	separator
	box "Restarting PostgreSQL"
	separator
	echo

	check_pg_installed || return 1
	check_pg_initialized || return 1

	pg_stop
	sleep 1
	pg_start

	echo
	separator
	log_success "PostgreSQL restarted"
	separator
	echo
}

# Estado de PostgreSQL
pg_status() {
	separator
	box "PostgreSQL Status"
	separator
	echo

	check_pg_installed || return 1

	# Intentar detectar la ruta de datos
	local found_dir=""
	local data_dirs=(
		"$PREFIX/var/lib/postgresql"
		"$PREFIX/var/lib/postgresql/data"
		"$PG_DATA"
		"$PG_DATA/data"
		"$HOME/.termux/postgresql"
		"$HOME/.termux/postgresql/data"
	)

	for dir in "${data_dirs[@]}"; do
		if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
			PG_DATA="$dir"
			found_dir="$dir"
			break
		fi
	done

	log_info "Checking PostgreSQL status..."
	echo

	# Verificar estado
	if [[ -n "$found_dir" ]]; then
		if pg_ctl -D "$found_dir" status &>/dev/null; then
			log_success "PostgreSQL is RUNNING"
			echo
			list_item "Data directory: $PG_DATA"
			list_item "Port: 5432"
			list_item "User: $PG_USER"
		else
			log_warn "PostgreSQL is STOPPED"
			echo
			list_item "Data directory: $PG_DATA"
			list_item "Run: ${D_CYAN}omni pg start${NC}"
		fi
	else
		log_warn "PostgreSQL is NOT INITIALIZED"
		echo
		list_item "Run: ${D_CYAN}omni pg init${NC} to initialize the database"
		list_item "Then run: ${D_CYAN}omni pg start${NC} to start the server"
	fi

	echo
}

# Crear base de datos
pg_create() {
	local db_name="$1"

	if [[ -z "$db_name" ]]; then
		log_error "Database name required"
		log_info "Usage: omni pg create <database_name>"
		return 1
	fi

	check_pg_installed || return 1

	# Detectar ruta de datos
	_detect_pg_data

	log_info "Creating database: $db_name..."

	if createdb "$db_name" &>/dev/null; then
		log_success "Database '$db_name' created successfully"
	else
		log_error "Failed to create database '$db_name'"
		log_warn "PostgreSQL may not be running. Run: omni pg start"
		return 1
	fi
}

# Eliminar base de datos
pg_drop() {
	local db_name="$1"

	if [[ -z "$db_name" ]]; then
		log_error "Database name required"
		log_info "Usage: omni pg drop <database_name>"
		return 1
	fi

	check_pg_installed || return 1

	log_warn "This will permanently delete database: $db_name"

	read_confirm "Are you sure?" CONFIRM
	if [[ "$CONFIRM" != "y" ]]; then
		log_warn "Operation cancelled"
		return 0
	fi

	# Detectar ruta de datos
	_detect_pg_data

	log_info "Dropping database: $db_name..."

	if dropdb "$db_name" &>/dev/null; then
		log_success "Database '$db_name' dropped successfully"
	else
		log_error "Failed to drop database '$db_name'"
		return 1
	fi
}

# Listar bases de datos
pg_list() {
	separator
	box "PostgreSQL Databases"
	separator
	echo

	check_pg_installed || return 1

	# Detectar ruta de datos
	_detect_pg_data

	log_info "Listing databases..."
	echo

	psql -c '\l' 2>/dev/null || {
		log_error "Failed to list databases"
		log_warn "PostgreSQL may not be running. Run: omni pg start"
		return 1
	}

	echo
}

# Abrir shell psql
pg_shell() {
	check_pg_installed || return 1

	# Detectar ruta de datos
	_detect_pg_data

	log_info "Opening psql shell..."
	echo

	psql 2>/dev/null
}

# Función auxiliar para detectar ruta de datos
_detect_pg_data() {
	local data_dirs=(
		"$PREFIX/var/lib/postgresql"
		"$PREFIX/var/lib/postgresql/data"
		"$PG_DATA"
		"$PG_DATA/data"
		"$HOME/.termux/postgresql"
		"$HOME/.termux/postgresql/data"
	)

	for dir in "${data_dirs[@]}"; do
		if [[ -d "$dir" ]] && [[ -f "$dir/PG_VERSION" ]]; then
			PG_DATA="$dir"
			return 0
		fi
	done

	return 1
}

_run_backup_cmd() {
	local db_name="$1"
	local file_path="$2"
	pg_dump -d "$db_name" -F c -b 2>/dev/null | gzip > "$file_path"
	return ${PIPESTATUS[0]}
}

_run_restore_cmd() {
	local db_name="$1"
	local file_path="$2"
	gunzip -c "$file_path" | pg_restore -d "$db_name" -c 2>/dev/null || gunzip -c "$file_path" | pg_restore -d "$db_name" 2>/dev/null
}

_pg_cleanup_old_backups() {
	local db_name="$1"
	local backup_dir="$OMNI_DATA/pg_backups"
	local retention_limit=10

	local -a backups=()
	while IFS= read -r f; do
		if [[ -n "$f" ]]; then
			backups+=("$f")
		fi
	done < <(find "$backup_dir" -name "${db_name}_*.backup.gz" -type f 2>/dev/null | sort)

	local count=${#backups[@]}
	if (( count > retention_limit )); then
		local to_delete=$(( count - retention_limit ))
		log_info "Cleaning up $to_delete old backup(s)..."
		for ((i=0; i<to_delete; i++)); do
			rm -f "${backups[$i]}" "${backups[$i]}.sha256"
			list_item "Deleted: $(basename "${backups[$i]}")"
		done
	fi
}

pg_backup() {
	check_pg_installed || return 1
	local db_name="$1"
	if [[ -z "$db_name" ]]; then
		read_input "Enter database name to backup" db_name
	fi
	if [[ -z "$db_name" ]]; then
		log_error "No database name provided"
		return 1
	fi

	# check if db exists
	if ! psql -lqt | cut -d \| -f 1 | grep -w "$db_name" &>/dev/null; then
		log_error "Database '$db_name' does not exist"
		return 1
	fi

	local backup_dir="$OMNI_DATA/pg_backups"
	mkdir -p "$backup_dir"
	local file_name="${db_name}_$(date +%Y%m%d_%H%M%S).backup.gz"
	local file_path="$backup_dir/$file_name"

	log_info "Creating compressed backup for '$db_name'..."
	if loading "Running backup dump" _run_backup_cmd "$db_name" "$file_path"; then
		# Integrity checksum
		sha256sum "$file_path" | cut -d' ' -f1 > "${file_path}.sha256"
		
		log_success "Backup created successfully:"
		list_item "$file_path"
		list_item "Checksum generated: $(cat "${file_path}.sha256")"
		
		# Cleanup old backups
		_pg_cleanup_old_backups "$db_name"
	else
		log_error "Failed to create backup"
		rm -f "$file_path"
		return 1
	fi
}

pg_restore() {
	check_pg_installed || return 1
	local db_name="$1"
	local backup_file="$2"

	local backup_dir="$OMNI_DATA/pg_backups"
	if [[ ! -d "$backup_dir" ]]; then
		log_error "No backups directory found: $backup_dir"
		return 1
	fi

	# List backups (both legacy .backup and new compressed .backup.gz)
	local -a files=()
	while IFS= read -r f; do
		if [[ -n "$f" ]]; then
			files+=("$f")
		fi
	done < <(find "$backup_dir" \( -name "*.backup" -o -name "*.backup.gz" \) 2>/dev/null | sort -r)

	if [[ ${#files[@]} -eq 0 ]]; then
		log_error "No backup files found in $backup_dir"
		return 1
	fi

	if [[ -z "$backup_file" ]]; then
		log_info "Select a backup file to restore:"
		local idx=0
		for f in "${files[@]}"; do
			printf "    ${D_GREEN}%2d.${D_NC} %s\n" $((idx + 1)) "$(basename "$f")"
			((idx++))
		done
		echo
		local pick
		read_input "Select backup file (#)" pick
		if [[ "$pick" =~ ^[0-9]+$ ]] && ((pick >= 1 && pick <= ${#files[@]})); then
			backup_file="${files[$((pick - 1))]}"
		else
			log_error "Invalid selection"
			return 1
		fi
	fi

	if [[ ! -f "$backup_file" ]]; then
		log_error "Backup file not found: $backup_file"
		return 1
	fi

	# Integrity verification
	if [[ -f "${backup_file}.sha256" ]]; then
		log_info "Verifying backup integrity..."
		local current_hash
		current_hash=$(sha256sum "$backup_file" | cut -d' ' -f1)
		local expected_hash
		expected_hash=$(cat "${backup_file}.sha256" 2>/dev/null)
		if [[ "$current_hash" != "$expected_hash" ]]; then
			log_warn "Integrity validation FAILED!"
			log_warn "Current SHA256: $current_hash"
			log_warn "Expected SHA256: $expected_hash"
			local confirm
			read_confirm "Continue restoring anyway?" confirm
			if [[ "$confirm" != "y" ]]; then
				log_error "Restoration aborted by user"
				return 1
			fi
		else
			log_success "Integrity check: OK"
		fi
	else
		log_warn "No SHA256 checksum file found. Integrity check skipped."
	fi

	if [[ -z "$db_name" ]]; then
		read_input "Enter target database name" db_name
	fi

	if [[ -z "$db_name" ]]; then
		log_error "No target database provided"
		return 1
	fi

	# Create db if not exists
	if ! psql -lqt | cut -d \| -f 1 | grep -w "$db_name" &>/dev/null; then
		log_info "Target database '$db_name' does not exist. Creating it..."
		if ! createdb "$db_name" &>/dev/null; then
			log_error "Failed to create target database '$db_name'"
			return 1
		fi
		log_success "Database '$db_name' created"
	fi

	log_info "Restoring backup into '$db_name'..."
	
	local success=false
	if [[ "$backup_file" == *.gz ]]; then
		if loading "Restoring compressed database" _run_restore_cmd "$db_name" "$backup_file"; then
			success=true
		fi
	else
		if loading "Restoring database" pg_restore -d "$db_name" -c "$backup_file" 2>/dev/null || pg_restore -d "$db_name" "$backup_file" 2>/dev/null; then
			success=true
		fi
	fi

	if [[ "$success" == "true" ]]; then
		log_success "Database '$db_name' restored successfully"
	else
		log_error "Failed to restore database. Make sure the database is compatible."
		return 1
	fi
}

pg_list_backups() {
	local backup_dir="$OMNI_DATA/pg_backups"
	separator
	box "Available PostgreSQL Backups"
	separator
	echo
	if [[ ! -d "$backup_dir" ]]; then
		log_info "No backups directory found"
		return 0
	fi

	local -a backups=()
	while IFS= read -r f; do
		if [[ -n "$f" ]]; then
			backups+=("$f")
		fi
	done < <(find "$backup_dir" \( -name "*.backup" -o -name "*.backup.gz" \) -type f 2>/dev/null | sort -r)

	if [[ ${#backups[@]} -eq 0 ]]; then
		log_info "No backup files found."
		separator
		return 0
	fi

	table_start "Database" "Backup File" "Size" "Date" "Integrity"
	for f in "${backups[@]}"; do
		local base=$(basename "$f")
		local db=$(echo "$base" | cut -d'_' -f1)
		local size=$(du -sh "$f" | awk '{print $1}')
		local date_str
		local date_part=$(echo "$base" | grep -oE '[0-9]{8}_[0-9]{6}')
		if [[ -n "$date_part" ]]; then
			date_str="${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${date_part:9:2}:${date_part:11:2}:${date_part:13:2}"
		else
			date_str="Unknown"
		fi

		local integrity="OK"
		if [[ -f "${f}.sha256" ]]; then
			local current_hash=$(sha256sum "$f" | cut -d' ' -f1)
			local expected_hash=$(cat "${f}.sha256" 2>/dev/null)
			if [[ "$current_hash" != "$expected_hash" ]]; then
				integrity="Corrupted"
			fi
		else
			integrity="No checksum"
		fi
		table_row "$db" "$base" "$size" "$date_str" "$integrity"
	done
	table_end
	echo
}

pg_schedule() {
	separator
	box "Schedule Automated PostgreSQL Backups"
	separator
	echo
	check_pg_installed || return 1

	local db_name
	read_input "Enter database name to schedule" db_name
	if [[ -z "$db_name" ]]; then
		log_error "Database name required"
		return 1
	fi

	local interval
	read_select "Select backup frequency" interval "Daily (2:00 AM)" "Weekly (Sundays 2:00 AM)" "Hourly" "Cancel"
	[[ "$interval" == "Cancel" ]] && return 0

	local cron_expr=""
	case "$interval" in
		"Daily (2:00 AM)") cron_expr="0 2 * * *" ;;
		"Weekly (Sundays 2:00 AM)") cron_expr="0 2 * * 0" ;;
		"Hourly") cron_expr="0 * * * *" ;;
	esac

	if [[ -n "$cron_expr" ]]; then
		if ! command -v crontab &>/dev/null; then
			log_warn "crontab command not found. Trying to install cronie..."
			pkg install -y cronie >/dev/null 2>&1 || true
		fi
		
		local job="$cron_expr OMNI_PATH=$OMNI_PATH $OMNI_PATH/bin/omni pg backup $db_name >/dev/null 2>&1"
		(crontab -l 2>/dev/null | grep -v "omni pg backup $db_name"; echo "$job") | crontab -
		log_success "Backup scheduled successfully ($interval) for database '$db_name'!"
		list_item "Ensure cron daemon is running (run: 'crond')"
	fi
	echo
}

# Función principal
pg_main() {
	local cmd="$1"
	shift || true

	case "$cmd" in
	start)
		pg_start
		;;
	stop)
		pg_stop
		;;
	restart)
		pg_restart
		;;
	status)
		pg_status
		;;
	init)
		pg_init
		;;
	create)
		pg_create "$2"
		;;
	drop)
		pg_drop "$2"
		;;
	backup)
		pg_backup "$@"
		;;
	restore)
		pg_restore "$@"
		;;
	list-backups | backups)
		pg_list_backups
		;;
	schedule)
		pg_schedule
		;;
	list | ls)
		pg_list
		;;
	shell | psql)
		pg_shell
		;;
	"")
		pg_help
		;;
	*)
		log_error "Unknown command: $cmd"
		pg_help
		exit 1
		;;
	esac
}
