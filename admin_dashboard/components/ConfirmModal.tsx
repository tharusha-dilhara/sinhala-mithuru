'use client';

interface Props {
  title: string;
  message: string;
  onConfirm: () => void;
  onCancel: () => void;
  loading?: boolean;
  danger?: boolean;
}

export default function ConfirmModal({ title, message, onConfirm, onCancel, loading, danger }: Props) {
  return (
    <div className="modal-backdrop" onClick={e => e.target === e.currentTarget && onCancel()}>
      <div className="modal-panel max-w-sm w-full p-6 animate-in">
        {/* Header */}
        <div className="flex items-center gap-3 mb-4">
          <div
            className="w-10 h-10 rounded-full flex items-center justify-center text-lg flex-shrink-0"
            style={{
              background: danger ? 'var(--danger-light)' : 'var(--primary-light)',
            }}
          >
            {danger ? '⚠️' : '❓'}
          </div>
          <h3 className="text-lg font-bold text-[var(--text-strong)]">{title}</h3>
        </div>

        <p className="text-sm text-[var(--text-body)] mb-6 leading-relaxed">
          {message}
        </p>

        <div className="flex gap-3 justify-end">
          <button onClick={onCancel} disabled={loading} className="btn btn-secondary">
            Cancel
          </button>
          <button
            onClick={onConfirm}
            disabled={loading}
            className={`btn ${danger ? 'btn-danger' : 'btn-primary'}`}
            style={{ opacity: loading ? 0.6 : 1 }}
          >
            {loading ? (
              <>
                <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2, borderTopColor: 'currentcolor', borderColor: 'rgba(0,0,0,0.15)' }} />
                Working...
              </>
            ) : (
              danger ? 'Delete' : 'Confirm'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
