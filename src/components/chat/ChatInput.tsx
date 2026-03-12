interface Props {
  value: string
  onChange: (value: string) => void
  onSend: () => void
  onKeyPress: (e: React.KeyboardEvent) => void
  disabled: boolean
  placeholder: string
}

export default function ChatInput({
  value,
  onChange,
  onSend,
  onKeyPress,
  disabled,
  placeholder,
}: Props) {
  return (
    <div className="flex items-end space-x-2">
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onKeyPress={onKeyPress}
        disabled={disabled}
        placeholder={placeholder}
        rows={1}
        className="flex-1 px-4 py-3 bg-gray-100 dark:bg-dark-surface rounded-2xl resize-none focus:outline-none focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
        style={{ minHeight: '44px', maxHeight: '120px' }}
      />
      <button
        onClick={onSend}
        disabled={disabled || !value.trim()}
        className="px-4 py-3 bg-primary-500 text-white rounded-2xl font-medium disabled:opacity-50 disabled:cursor-not-allowed active:scale-95 transition-transform"
      >
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
        </svg>
      </button>
    </div>
  )
}
