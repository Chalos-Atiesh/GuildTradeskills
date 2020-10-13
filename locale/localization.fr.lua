local AddOnName, GT = ...

local GREEN = '|cff3ce13f'
local YELLOW = '|cffe0ca0a'
local COLOR_END = '|r'

local L = LibStub('AceLocale-3.0'):NewLocale(AddOnName, 'frFR', false, true)

local LONG_TAG = GREEN .. 'Guild' .. COLOR_END .. YELLOW .. 'Tradeskills' .. COLOR_END
local WHISPER_TAG = 'GT: '
local TRIGGER_CHAR = '?'

local ONLINE = 'En ligne'
local OFFLINE = 'Hors ligne'

local CHARACTER_NIL = 'Vous devez ajouter le nom d\'un personnage. \''

local ALCHEMY = 'Alchimie'
local BLACKSMITHING = 'Forgeron'
local ENCHANTING = 'Enchantement'
local ENGINEERING = 'Ingénierie'
local LEATHERWORKING = 'Travail du cuir'
local TAILORING = 'Couture'
local COOKING = 'Cuisine'

if L then
	---------- CLASSES START ----------

	-- The KEY should be the localized value here.
	-- It should be in all caps.
	-- We use it for getting class colors.
	L['DRUIDE'] = 'DRUID'
	L['CHASSEUR'] = 'HUNTER'
	L['MAGE'] = 'MAGE'
	L['PALADIN'] = 'PALADIN'
	L['PRETRE'] = 'PRIEST'
	L['VOLEUR'] = 'ROGUE'
	L['CHAMAN'] = 'SHAMAN'
	L['DEMONISTE'] = 'WARLOCK'
	L['GUERRIER'] = 'WARRIOR'

	---------- CHARACTER START ----------

	L['CHARACTER'] = 'Personnage'

	L['CHARACTER_RESET_NOT_FOUND'] = 'Impossible de trouver ce personnage: \'{{character_name}}\'.'
	L['CHARACTER_RESET_FINAL'] = 'Personnage correctement réinitialisé \'{{character_name}}\'.'

	---------- CHARACTER END ----------
	---------- COMMAND START ----------

	L['UNKNOWN_COMMAND'] = 'Désolé, je n\'ai pas trouvé la commande \'{{command}}\'. Tapez \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' pour obtenir une liste des commandes disponibles.'
	--@debug@
	L['FORCE'] = 'force'
	--@end-debug@

	L['SLASH_COMMANDS'] = {
		gt = {
			order = 0,
			methodName = 'OnCommand',
			help = YELLOW .. '/gt' .. COLOR_END .. ': Ouvre et ferme le panneau de recherche.',
			subCommands = {
				help = {
					order = 0,
					methodName = 'Help',
					help = YELLOW .. '/gt help' .. COLOR_END .. ': Affiche ce message.'
				},
				opt = {
					order = 1,
					methodName = 'Options',
					help = YELLOW .. '/gt opt' .. COLOR_END .. ': Ouvre et ferme le panneau des options.'
				},
				addprofession = {
					order = 2,
					methodName = 'InitAddProfession',
					help = YELLOW .. '/gt addprofession' .. COLOR_END .. ': Ajoute un métier. Ouvrez  le métier après avoir lancer la commande.'
				},
				removeprofession = {
					order = 3,
					methodName = 'RemoveProfession',
					help = YELLOW .. '/gt removeprofession {profession_name}' .. COLOR_END .. ': Supprime un métier.'
				},
				--[[
				advertise = {
					order = 4,
					methodName = 'ToggleAdvertising',
					help = YELLOW .. '/gt advertise' .. COLOR_END .. ': Active et désactive vos annonces de métier.',
					subCommands = {
						seconds = {
							parens = true,
							methodName = 'ToggleAdvertising',
							help =  YELLOW .. '/gt advertise {seconds}' .. COLOR_END .. ': Règle le délai en secondes entre les annonces.'
						}
					}
				},
				--]]
				add = {
					order = 5,
					methodName = 'SendRequest',
					help = YELLOW .. '/gt add {character_name}' .. COLOR_END .. ': Demande d\'ajout d\'un personnage.'
				},
				reject = {
					order = 6,
					methodName = 'SendReject',
					help = YELLOW .. '/gt reject {character_name}' .. COLOR_END .. ': Rejette la demande d\'ajout de quelqu\'un. Il peut refaire une demande.'
				},
				ignore = {
					order = 7,
					methodName = 'SendIgnore',
					help = YELLOW .. '/gt ignore {character_name}' .. COLOR_END .. ': Ignore cette personne. Aucune de ces demandes ne sera plus affichée.'
				},
				requests = {
					order = 8,
					methodName = 'ShowRequests',
					help = YELLOW .. '/gt requests' .. COLOR_END .. ': Liste les personnages qui ont demandé à vous ajouter.'
				},
				broadcast = {
					order = 9,
					methodName = 'ToggleBroadcast',
					help = YELLOW .. '/gt broadcast' .. COLOR_END .. ': Active ou désactive les options de diffusion.',
					subCommands = {
						send = {
							order = 0,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast send' .. COLOR_END .. ': Active ou désactive si vous annoncez à tout le monde. ' .. YELLOW .. 'Oui, vraiment tout le monde.' .. COLOR_END
						},
						receive = {
							order = 1,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast receive' .. COLOR_END .. ': Active ou désactive si vous recevez les annonces de tout le monde. ' .. YELLOW .. 'Oui, vraiment tout le monde.' .. COLOR_END
						},
						sendforwards = {
							order = 2,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast sendforwards' .. COLOR_END .. ': Active ou désactive si vous transmettez les anonnces reçues. ' .. YELLOW .. 'Soyez prudent, peut impacter vos performances.' .. COLOR_END
						},
						receiveforwards = {
							order = 3,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast receiveforwards' .. COLOR_END .. ': Active ou désactive si vous acceptez les anonnces transmises par d\'autres. ' .. YELLOW .. 'Soyez prudent, peut impacter vos performances.' .. COLOR_END
						}

					}
				},
				window = {
					order = 10,
					methodName = 'SetChatFrame',
					help = YELLOW .. '/gt window {window_name}' .. COLOR_END .. ': Affiche dans une fenêtre de chat.'
				},
				reset = {
					order = 11,
					methodName = 'Reset',
					help = YELLOW .. '/gt reset' .. COLOR_END .. ': Remet à zéro toutes les données. |cffff0000Tout sera perdu, irréversible.|r'
				}
			}
		}
	}

	L['RESET_WARN'] = 'En êtes-vous bien sûr? Remettra tout l\'addon à zéro. Entrer \'/gt reset confirm\' pour confirmer ou \'/gt reset cancel\' pour annuler.'
	L['RESET_EXPECT_COMFIRM'] = 'confirm'
	L['RESET_EXPECT_CANCEL'] = 'cancel'
	L['RESET_NO_CONFIRM'] = 'Commande non comprise ! Entrer soit \'/gt reset confirm\' pour confirmer ou \'/gt reset cancel\' pour annuler.'
	L['RESET_CANCEL'] = 'Annulation de la remise à zéro.'
	L['RESET_CHARACTER'] = 'Remise à zéro du personnage \'{{character_name}}\' après avertissement.'
	L['RESET_PROFESSION'] = 'Remise à zéro du métier \'{{profession_name}}\' après avertissement.'
	L['RESET_FINAL'] = 'Remise à zéro de tout l\'addon après avertisssement.'
	L['RESET_UNKNOWN'] = 'Désolé, je ne comprends pas: \'{{token}}\' is.'

	---------- COMMAND END ----------
	---------- WHISPER START ----------

	L['TRIGGER_CHAR'] = TRIGGER_CHAR

	L['QUERY_TOOLTIP'] = 'Clic droit pour demander: {{skill}}'

	L['WHISPER_TAG'] = WHISPER_TAG
	L['WHISPER_FIRST_PROFESSION'] = '{{profession_name}}'
	L['WHISPER_SECOND_PROFESSION'] = ' et {{profession_name}}'
	L['WHISPER_PROFESSION_NOT_FOUND'] = WHISPER_TAG .. 'Désolé, on dirait que je n\'ai pas \'{{profession_search}}\'. J\'ai: {{first_profession}}{{second_profession}}.'
	L['WHISPER_NIL_PROFESSIONS'] = WHISPER_TAG .. 'Je n\'ai pas encore ajouter de profession. Redemandez plus tard !'

	L['WHISPER_INVALID_PAGE'] = WHISPER_TAG .. 'Désolé, la page {{page}} n\'est pas valide. Je n\'ai que {{max_pages}} pages.'
	L['WHISPER_HEADER'] = WHISPER_TAG .. 'Page {{current_page}} sur {{total_pages}}. J\'ai {{total_skills}} talents.'
	L['WHISPER_ITEM'] = WHISPER_TAG .. '{{number}}. {{skill_link}}'
	L['WHISPER_FOOTER'] = WHISPER_TAG .. 'Vous pouvez avoir la page suivante en répondant \'' .. TRIGGER_CHAR .. '{{profession_name}} {{next_page}}\' ou sauter à la page en répondant \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\'.'
	L['WHISPER_FOOTER_LAST_PAGE'] = WHISPER_TAG .. 'Vous pouvez aller à la page en répondant \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\'.'

    L['WHISPER_REQUEST'] = WHISPER_TAG .. 'Salut {{character_name}}! Pouvez-vous me crafter {{item_link}} ?'
    L['WHISPER_SELECT_REQUIRED'] = 'Pas de talent sélectionné. Vous devez d\'abord sélectionner un talent.'
    L['WHISPER_NO_CHARACTER_FOUND'] = 'Le personnage \'{{character_name}}\' n\'a pas l\'air d\'être connecté.'

    L['WHISPER_INCOMING_REQUESTS'] = 'Vous avez reçu des requêtes de: {{character_names}}'
    L['WHISPER_NO_INCOMING_REQUESTS'] = 'Vous n\'avez pas de requêtes.'

	---------- WHISPER END ----------
	---------- LOG START ----------

	L['LOG_TAG'] = GREEN .. 'G' .. COLOR_END .. YELLOW .. 'T' .. COLOR_END .. ': '

	L['DUMP_PROFESSION_NIL'] = 'Vous devez passer un métier: /gt dumpprofession {profession_name}'
	L['DUMP_PROFESSION_NOT_FOUND'] = 'Désolé, je ne connais pas ce métier: {{profession_name}}'
	L['DUMP_PROFESSION'] = 'Envoi du métier: {{profession_name}}'

	L['DUMP_CHARACTER_NIL'] = 'Vous devez passer le nom d\'un personnage: /gt dumpcharacter {character_name}'
	L['DUMP_CHARACTER_NOT_FOUND'] = 'Désolé, je n`\'ai pas trouvé le personnage: {{character_name}}'
	L['DUMP_CHARACTER'] = 'Envoi du personnage: {{character_name}}'

	---------- LOG END ----------
	---------- PROFESSION START ----------

	L['PROFESSION'] = 'métier'

	L['PROFESSIONS_LIST'] = {
		ALCHEMY = ALCHEMY,
		BLACKSMITHING = BLACKSMITHING,
		ENCHANTING = ENCHANTING,
		ENGINEERING = ENGINEERING,
		LEATHERWORKING = LEATHERWORKING,
		TAILORING = TAILORING,
		COOKING = COOKING
	}

	L['PROFESSION_ADD_INIT'] = 'Ouvrez le métier à ajouter.'
	L['PROFESSION_ADD_CANCEL'] = 'Annulation de l\'ajout du métier.'
	L['PROFESSION_ADD_PROGRESS'] = 'Récupération des données serveur. Celà ne devrait prendre que quelques secondes.'
	L['PROFESSION_ADD_SUCCESS'] = 'Métier correctement ajouté: {{profession_name}}'
	L['PROFESSION_REMOVE_NIL_PROFESSION'] = 'Il manque le métier. Vous pouver retirer un métier avec: \'/gt removeprofession {prfession_name}'
	L['PROFESSION_REMOVE_NOT_FOUND'] = 'Métier introuvable \'{{profession_name}}\' pour le personnage \'{{character_name}}\'.'
	L['PROFESSION_REMOVE_SUCCESS'] = 'Métier correctement retiré \'{{profession_name}}\' du personnage \'{{character_name}}\'.'

	L['PROFESSION_RESET_NOT_FOUND'] = 'Métier introuvable: {{profession_name}}'
	L['PROFESSION_RESET_FINAL'] = 'Métier correctement remis à zéro: {{profession_name}}'

	---------- PROFESSION END ----------
	---------- GUI START ----------

		---------- OPTIONS START -----------

		L['LABEL_OPEN_SEARCH'] = 'Recherche Ouverte'
		L['DESC_OPEN_SEARCH'] = 'Ouvre le panneau de recherche.'

		L['LABEL_SHOW_LOGIN_MESSAGE'] = 'Message de connexion'
		L['DESC_SHOW_LOGIN_MESSAGE'] = 'Indique si le message de connexion est imprimé.'

		L['CANCEL'] = 'Cancel'
		L['OKAY'] = 'Okay'

		L['DESC_PROFESSIONS'] = 'Les métiers suivis sur ce personnage.'

		L['PROFESSION_ADD_NAME'] = 'Ajouter un métier'
		L['PROFESSION_ADD_DESC'] = 'Ajouter un métier sur ce personnage.'
		L['PROFESSION_ADD_CANCEL_DESC'] = 'Annulation d\'ajoût de métier.'

		L['PROFESSION_DELETE_NAME'] = 'Supprimer le métier'
		L['PROFESSION_DELETE_DESC'] = 'Arrêter de suivre ce métier sur ce personnager.'
		L['PROFESSION_DELETE_CONFIRM'] = 'Êtes-vous certain de vouloir arrêter de suivre {{profession_name}}?'

		L['LABEL_ADD_CHARACTER'] = 'Ajouter un personnage hors guilde'
		L['DESC_ADD_CHARACTER'] = 'Ajout d\'un personnage qui ne fait pas partie de votre guilde.'

		L['LABEL_NON_GUILD_CHARACTERS'] = 'Personnages hors guildés'
		L['DESC_NON_GUILD_CHARACTERS'] = 'Personnages que vous avez ajouté mais qui ne sont pas dans votre guilde.'

		L['LABEL_CHARACTER_REMOVE'] = 'Retirer ce personnage'
		L['DESC_CHARACTER_REMOVE'] = 'Arrêter de suivre ce personnage.'
		L['CHARACTER_REMOVE_CONFIRM'] = 'Êtes-vous certains de vouloir retirer: {{character_name}} ?'

		L['LABEL_REQUESTS_TOGGLE_ALL'] = 'Tout autoriser'
		L['LABEL_REQUESTS_TOGGLE_CONFIRM'] = 'Confirmation requise'
		L['LABEL_REQUESTS_TOGGLE_NONE'] = 'Tout interdire'
		L['DESC_REQUESTS_TOGGLE'] = 'Détermine combien de demandes vous autorisez.'

		L['LABEL_REQUESTS'] = 'Demandes'
		L['DESC_REQUESTS'] = 'Ces joueurs ont demandé à vous ajouter.'

		L['LABEL_SEND_CONFIRM'] = 'Accepter'
		L['DESC_SEND_CONFIRM'] = 'Accepter leurs demandes.'

		L['LABEL_SEND_REJECT'] = 'Refuser'
		L['DESC_SEND_REJECT'] = 'Refuser leurs demandes.'

		L['LABEL_SEND_IGNORE'] = 'Ignorer'
		L['DESC_SEND_IGNORE'] = 'Ignorer ce joueur.'
		L['CHARACTER_IGNORE_CONFIRM'] = 'Êtes-vous sûr de vouloir ignorer {{character_name}}?'

		L['LABEL_ADVERTISING'] = 'Annonces'
		L['DESC_ADVERTISE_TOGGLE'] = 'Active ou désactive les annonces auto.'

		L['LABEL_ADVERTISING_INTERVAL'] = 'Intervalle entre les annonces'
		L['DESC_ADVERTISING_INTERVAL'] = 'Combien de minutes entre les annonces.'

		L['BROADCASTING'] = 'Diffusion'

		L['LABEL_BROADCAST_INTERVAL'] = 'Intervalle de diffusion'
		L['DESC_BROADCAST_INTERVAL'] = 'Combien de minutes entre chaque diffusion.'

		L['LABEL_SEND_BROADCAST'] = 'Envoi de diffusion'
		L['DESC_SEND_BROADCAST'] = 'Envoi de vos talents à tout le monde.'
		L['CONFIRM_SEND_BROADCAST'] = 'Vous allez diffuser vos talents à tout le monde. Vraiment out le monde. Êtes-vous certain ?'

		L['LABEL_RECEIVE_BROADCASTS'] = 'Acceptation des diffusions'
		L['DESC_RECEIVE_BROADCASTS'] = 'Acception des diffusions de tout le monde.'
		L['CONFIRM_RECEIVE_BROADCASTS'] = 'Tout le monde pourra s\'ajouter. Vraiment tout le monde. Êtes-vous certain ?'

		L['LABEL_SEND_FORWARDS'] = 'Transmission des diffusions'
		L['DESC_SEND_FORWARDS'] = 'Transmission des diffusions aux autres joueurs.'
		L['CONFIRM_SEND_FORWARDS'] = 'Cette option est en bêta. Vous pourriez rencontrer des problèmes. Vous allez transmettre toutes les diffusions. Êtes-vous certain ?'
		L['LABEL_RECEIVE_FORWARDS'] = 'Accept Forwards'
		L['DESC_RECEIVE_FORWARDS'] = 'Accept forwarded broadcasts.'
		L['CONFIRM_RECEIVE_FORWARDS'] = 'Cette option est en bêta. Vous pourriez rencontrer des problèmes. Vous allez accepter toutes les diffusions transmises. Êtes-vous certain ?'

		---------- OPTIONS END ----------

	L['BARE_LONG_TAG'] = 'GuildTradeskills'
	L['LONG_TAG'] = LONG_TAG

	L['WELCOME'] = 'Bienvenue à ' .. LONG_TAG .. '! Pour voir l\'aide, entrer: \'/gt help\'.'

	L['SEARCH_SKILLS'] = 'Chercher des talents:'
    L['SEARCH_REAGENTS'] = 'Chercher des réactifs:'
    L['SEARCH_CHARACTERS'] = 'Chercher des personnages:'
    L['LABEL_SKILLS'] = 'Talents'
    L['LABEL_PROFESSIONS'] = 'Métiers'
    L['LABEL_REAGENTS'] = 'Réactifs'
    L['LABEL_CHARACTERS'] = 'Personnages'

    L['BUTTON_FILTERS_RESET'] = 'Effacer les filtres'

    L['ONLINE'] = ONLINE
    L['OFFLINE'] = OFFLINE
	L['BROADCASTED_TAG'] = '|cff7f7f7f{{guild_member}}|r'
	L['OFFLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff7f7f7f' .. OFFLINE ..'|r'
	L['ONLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff00ff00' .. ONLINE .. '|r'

	L['CHAT_FRAME_NIL'] = 'Il manque le nom de la fenêtre de chat. Entrer: ' .. YELLOW .. '\'/gt chatwindow {window_name}\'' .. COLOR_END ..'.'
	L['CHAT_WINDOW_SUCCESS'] = 'Fenêtre de chat: \'{{frame_name}}\'.'
	L['CHAT_WINDOW_INVALID'] = 'Désolé, je ne trouve aucune fenêtre de chat: \'{{frame_name}}\'.'

	L['UPDATE_AVAILABLE'] = LONG_TAG .. ' n\'est plus à jour. Votre version est {{local_version}} alors que la version {{remote_version}} est disponible.'

	L['CORRUPTED_DATABASE'] = 'On dirait que votre base de données est malheureusement corrompue. Vous pouvez la remettre à zéro avec \'/gt reset\'.'

	L['NO_SKILL_SELECTED'] = 'Vous devez sélectionner une compétence avant de chuchoter un personnage.'
	L['SEND_WHISPER'] = WHISPER_TAG .. 'Salut {{character_name}}! Pouvez-vous créer {{skill_link}} pour moi?'

	---------- GUI END ----------
	---------- ADVERTISE START ----------

	L['ADVERTISE_ON'] = 'Annonces en cours!'
	L['ADVERTISE_OFF'] = 'Annonces arrêtées.'

	L['ADVERTISING_INVALID_INTERVAL'] = '\'{{interval}}\' est un intervalle de temps invalide. Il doit être en secondes.'
	L['ADVERTISE_MINIMUM_INTERVAL'] = 'Un intervalle de {{interval}} secondes est trop court. Je mets le minimum: {{minimum_interval}} secondes.'
	L['ADVERTISE_SET_INTERVAL'] = 'Réglage de l\'intervalle d\'annonce à {{interval}} seconded.'
	L['ADVERTISE_NO_PROFESSIONS'] = 'Oh oh! On dirait qu\'il n\'y aucune profession ajoutée dans l\'addon. Vous pouvez les ajouter avec: \'/gt addprofession\'.' 

	L['ADVERTISE_FIRST_PROFESSION'] = '{{skill_count}} {{profession_name}}'
	L['ADVERTISE_SECOND_PROFESSION'] = ' et {{skill_count}} {{profession_name}}'
	L['ADVERTISE_FIRST_WHISPER'] = '\'' .. TRIGGER_CHAR .. '{{profession_name}}\' ou \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\''
	L['ADVERTISE_SECOND_WHISPER'] = ' ou \'' .. TRIGGER_CHAR .. '{{profession_name}}\' ou \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\'' 
	L['ADVERTISE_ADVERTISEMENT'] = WHISPER_TAG .. 'J\'offre mes services de craft ! Je suis {{first_profession}}{{second_profession}}. Whispez moi {{first_whisper}}{{second_whisper}}.'
	---------- ADVERTISE END ----------
	---------- BROADCAST START ----------
	L['SEND'] = 'send'
	L['RECEIVE'] = 'receive'
	L['SEND_FORWARDS'] = 'sendforwards'
	L['RECEIVE_FORWARDS'] = 'receiveforwards'
	L['BROADCAST_UNKNOWN'] = 'Désolé, je ne connais pas le type de diffusion \'{{broadcast_type}}\'.'

	L['BROADCAST_SEND_ON'] = 'Vous diffusez maintenant à tout le monde.'
	L['BROADCAST_SEND_OFF'] = 'Vous ne diffusez plus à tout le monde.'

	L['BROADCAST_RECEIVE_ON'] = 'Vous acceptez maintenant les diffusions de tout le monde.'
	L['BROADCAST_RECEIVE_OFF'] = 'Vous n\'acceptez plus les diffusions de tout le monde.'

	L['BROADCAST_SEND_FORWARD_ON'] = 'Vous transférez maintenant les diffusions.'
	L['BROADCAST_SEND_FORWARD_OFF'] = 'Vous ne transférez plus les diffusions.'

	L['BROADCAST_FORWARDING_ON'] = 'Vous envoyez et acceptez maintenant toutes les diffusions trasmises.'
	L['BROADCAST_FORWARDING_OFF'] = 'Vous n\'acceptez et n\'envoyez plus les diffusions transmises.'
	L['BROADCAST_FORWARD_UNKNOWN'] = 'Désolé, je ne connais pas le type de diffusion: \'{{broadcast_type}}\'.'

	L['BROADCAST_ALL_ON'] = 'Vous envoyez et acceptez maintenant toutes les diffusions.'
	L['BROADCAST_ALL_OFF'] = 'Vous n\'acceptez plus et n\'envoyez plus aucune diffusion.'

	---------- BROADCAST END ----------
	---------- NON-GUILD REQUEST START ----------

	L['REQUEST_ADDON_NOT_INSTALLED'] = 'On dirait que {{character_name}} n\'a pas installé ' .. LONG_TAG .. '.'

	L['REQUEST_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['REQUEST_NOT_SELF'] = 'Vous ne pouvez pas vous ajouter vous-même.'
	L['REQUEST_NOT_GUILD'] = '{{character_name}} est un compagnon de guilde, vous ne pouvez pas l\'ajouter.'
	L['REQUEST_REPEAT'] = 'Vous avez déjà envoyé une requête à {{character_name}}. Vous ne pouvez pas en renvoyer.'
	L['REQUEST_EXISTS'] = 'Vous avez déjà ajouté {{character_name}}. Vous ne pouvez pas l\'ajouter une nouvelle fois.'
	L['REQUEST_INCOMING'] = '{{character_name}} voudrait vous ajouter en ' .. LONG_TAG .. '. Entrer \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' pour voir quoi faire.'

	L['CONFIRM_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['CONFIRM_NOT_SELF'] = 'Vous ne pouvez pas vous auto confirmer.'
	L['CONFIRM_NOT_GUILD'] = '{{character_name}} est dans votre guilde, vous ne pouvez pas le confirmer.'
	L['CONFIRM_REPEAT'] = 'Vous avez déjà envoyé une confirmation à {{character_name}}. Vous ne pouvez pas en renvoyer.'
	L['CONFIRM_EXISTS'] = 'Vous avez déjà confirmé {{character_name}}. Vous ne pouvez pas le confirmer une deuxième fois.'
	L['CONFIRM_INCOMING'] = '{{character_name}} a accepté votre requête ! Vous devriez voir ses capacités dans pas longtemps.'
	L['CONFIRM_NIL'] = '{{character_name}} ne vous a pas envoyé de confirmation.'

	L['REJECT_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt reject {character_name}' .. COLOR_END .. '\'.'
	L['REJECT_NOT_SELF'] = 'Vous ne pouvez pas rejeter votre propre demande.'
	L['REJECT_NOT_GUILD'] = 'Désolé, {{character_name}} est membre de votre guilde, vous ne pouvez pas le rejeter.'
	L['REJECT_ALREADY_IGNORED'] = 'Vous avez déjà ignoré {{character_name}}. Vous ne pouvez pas le réignorer.'
	L['REJECT_REPEAT'] = 'Vous avez déjà envoyé un rejet à {{character_name}}. Vous ne pouvez pas en renvoyer un autre pour l\'instant.'
	L['REJECT_NIL'] = '{{character_name}} ne vous a pas envoyé une demande de rejet.'
	L['IGNORE_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt ignore {character_name}' .. COLOR_END .. '\'.'
	L['IGNORE_NOT_SELF'] = 'Vous ne pouvez pas vous ignorer.'
	L['IGNORE_NOT_GUILD'] = '{{character_name}} est membre de votre giulde, vous ne pouvez pas l\'ignorer.'
	L['IGNORE_REPEAT'] = 'Vous avez déjà ignoré {{character_name}}. Vous ne pouvez pas l\'ignorer une nouvelle fois.'
	L['IGNORE_INCOMING'] = '{{character_name}} vous a ignoré. Vous ne pouvez plus lui envoyer de demandes.'
	L['IGNORE_OUTGOING'] = '{{character_name}} a été ajouté à la liste des personnages ignorés. Vous ne devriez plus recevoir de requêtes de ce compte.'
	L['IGNORE_REMOVE'] = '{{character_name}} a été retiré de a liste des personnages ignorés. Vous pouvez de nouveau recevoir des demandes de sa part.'
	L['IGNORE_ALREADY_IGNORED'] = 'Vous avez déjà ignoré {{character_name}}. Vous ne pouvez pas l\'ignorer une deuxième fois.'

	L['CHARACTER_NOT_FOUND'] = 'Désolé, \'{{character_name}}\' n\'a pas l\'air d\'exister.'

	L['INCOMING_REQUEST'] = '{{character_name}} voudrait vous ajouter en ' .. LONG_TAG .. '. Entrer \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' pour voir quoi faire.'
	L['INCOMING_CONFIRM'] = '{{character_name}} a accepté votre demande ! Vous devriez voir ses capacités dans pas longtemps.'
	L['INCOMING_REJECT'] = '{{character_name}} a rejeté votre invitation.'
	L['INCOMING_IGNORE'] = 'Vous avez été ignoré par {{character_name}}. Vous ne pouvez plus lui envoyer de demandes.'

	L['INCOMING_REQUEST_TIMEOUT'] = 'La demande à {{character_name}} a expiré et est annulée. Vous pouvez redemander  avec:\'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'

	L['OUTGOING_REQUEST_ONLINE'] = 'Une requête a été envoyée à {{character_name}}. S\'il accepte, il sera ajouté à votre liste.'
	L['OUTGOING_CONFIRM_ONLINE'] = 'Demande acceptée par{{character_name}} ! Vous devriez voir ses capacités dans pas longtemps.'
	L['OUTGOING_REJECT_ONLINE'] = 'Votre rejet a été envoyé à {{character_name}}.'
	L['OUTGOING_IGNORE_ONLINE'] = '{{character_name}} a été informé qu\'il a été ignoré.'

	L['OUTGOING_REQUEST_TIMEOUT'] = 'Votre demande à{{character_name}} a expiré et a été annulée. Vous pouvez redemander avec \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['OUTGOING_CONFIRM_TIMEOUT'] = 'Votre confirmation à {{character_name}} a expiré. Vous pouvez la rafraichir avec \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['OUTGOING_REJECT_TIMEOUT'] = 'Votre rejet à {{character_name}} a expiré. Vous pouvez le refraichir avec \'' .. YELLOW .. '/gt reject {character_name}' .. COLOR_END .. '\'.'
	L['OUTGOING_IGNORE_TIMEOUT'] = 'L\'envoie de votre ignore sur {{character_name}} a expiré. Cependant, il ne pourra pas quand même plus vous envoyer de demandes.'

	L['OUTGOING_REQUEST_OFFLINE'] = '{{character_name}} n\'est pas en ligne. La demande sera renvoyée quand vous serez tous les deux en ligne.'
	L['OUTGOING_CONFIRM_OFFLINE'] = '{{character_name}} n\'est pas en ligne. La confirmation sera faite quand vous serez tous les deux en ligne.'
	L['OUTGOING_REJECT_OFFLINE'] = '{{character_name}} n\'est pas en ligne. Le rejet sera renvoyé quand vous serez tous les deux en ligne.'
	L['OUTGOING_IGNORE_OFFLINE'] = '{{character_name}} n\'est pas en ligne. L\'envoie de l\'ignore sera fait quand vous serez tous les deux en ligne et il ne pourra plus vous faire de demandes.'

	---------- NON-GUILD REQUEST END ----------
	---------- MISC START ----------

	L['PRINT_DELIMITER'] = ', '
	L['ADDED_BY'] = 'Ajouté par'
	L['X'] = 'x'

	L['REMOVE_GUILD'] = 'Ces personnages ne font plus partie de votre guilde et ont été supprimés: {{character_names}}'
	L['REMOVE_GUILD_INACTIVE'] = 'Ces membres de guilde sont inactifs depuis {{timeout_days}} jours et ont été supprimés: {{character_names}}'


	L['REMOVE_WHISPER_INACTIVE'] = 'Ces personnages que vous avez ajoutés manuellement sont inactifs depuis {{timeout_days}} jours et ont été supprimé: {{character_names}}'

	---------- MISC END ----------
end
